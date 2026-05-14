import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import Stripe from "stripe";

admin.initializeApp();

const db = admin.firestore();

const RES_MIN = 3;
const RES_MAX = 15;
const DEFAULT_TTL_MIN = 10;
const MAX_CART_LINES = 20;

type HoldLine = { foodItemId: string; quantity: number };

function requireAuthUid(context: functions.https.CallableContext): string {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in."
    );
  }
  return context.auth.uid;
}

/**
 * Callable: temporarily reserve cart quantities for checkout (replaces any prior active holds for this user).
 * Uses a denormalized `reservedStock` counter on `food_items` plus `stock_reservations` docs for expiry/audit.
 */
export const placeStockReservations = functions.https.onCall(
  async (data, context) => {
    const userId = requireAuthUid(context);

    const rawItems = data?.items as HoldLine[] | undefined;
    const rawTtl = data?.ttlMinutes;
    let ttlMinutes = DEFAULT_TTL_MIN;
    if (typeof rawTtl === "number" && Number.isFinite(rawTtl)) {
      ttlMinutes = Math.round(rawTtl);
    }
    ttlMinutes = Math.min(RES_MAX, Math.max(RES_MIN, ttlMinutes));

    if (!rawItems || !Array.isArray(rawItems) || rawItems.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "items must be a non-empty array of { foodItemId, quantity }."
      );
    }
    if (rawItems.length > MAX_CART_LINES) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `At most ${MAX_CART_LINES} line items per reservation.`
      );
    }

    const normalized: HoldLine[] = [];
    for (const line of rawItems) {
      const fid =
        typeof line.foodItemId === "string" ? line.foodItemId.trim() : "";
      const qty =
        typeof line.quantity === "number"
          ? Math.floor(line.quantity)
          : parseInt(String(line.quantity), 10);
      if (!fid) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Each item needs a foodItemId."
        );
      }
      if (!Number.isFinite(qty) || qty < 1) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Each quantity must be at least 1."
        );
      }
      normalized.push({ foodItemId: fid, quantity: qty });
    }

    const merged = new Map<string, number>();
    for (const line of normalized) {
      merged.set(
        line.foodItemId,
        (merged.get(line.foodItemId) ?? 0) + line.quantity
      );
    }
    const mergedLines: HoldLine[] = [...merged.entries()].map(
      ([foodItemId, quantity]) => ({ foodItemId, quantity })
    );

    const nowMs = Date.now();
    const expires = admin.firestore.Timestamp.fromMillis(
      nowMs + ttlMinutes * 60 * 1000
    );
    const nowTs = admin.firestore.Timestamp.fromMillis(nowMs);

    const existingSnap = await db
      .collection("stock_reservations")
      .where("userId", "==", userId)
      .where("expirationTimestamp", ">", nowTs)
      .get();

    await db.runTransaction(async (tx) => {
      const existingHolds: Array<{
        ref: admin.firestore.DocumentReference;
        foodItemId: string;
        quantity: number;
      }> = [];
      const releaseQtyByFood = new Map<string, number>();

      for (const doc of existingSnap.docs) {
        const fresh = await tx.get(doc.ref);
        if (!fresh.exists) continue;
        const d = fresh.data()!;
        const foodItemId = d.foodItemId as string;
        const quantity = (d.reservedQuantity as number) || 0;
        if (!foodItemId || quantity < 1) continue;
        existingHolds.push({ ref: doc.ref, foodItemId, quantity });
        releaseQtyByFood.set(
          foodItemId,
          (releaseQtyByFood.get(foodItemId) ?? 0) + quantity
        );
      }

      const newQtyByFood = new Map<string, number>();
      for (const line of mergedLines) {
        newQtyByFood.set(
          line.foodItemId,
          (newQtyByFood.get(line.foodItemId) ?? 0) + line.quantity
        );
      }

      const foodIds = new Set<string>([
        ...releaseQtyByFood.keys(),
        ...newQtyByFood.keys(),
      ]);
      const foodSnaps = new Map<
        string,
        admin.firestore.DocumentSnapshot<admin.firestore.DocumentData>
      >();
      for (const foodId of foodIds) {
        const foodRef = db.collection("food_items").doc(foodId);
        foodSnaps.set(foodId, await tx.get(foodRef));
      }

      for (const line of mergedLines) {
        const foodSnap = foodSnaps.get(line.foodItemId);
        if (!foodSnap || !foodSnap.exists) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "An item in your cart is no longer available."
          );
        }
        const fd = foodSnap.data()!;
        const statusStr = (fd.status as string) ?? "active";
        if (statusStr !== "active") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "An item in your cart is no longer available."
          );
        }
        const closingRaw = fd.closingTime;
        let closingMs: number | null = null;
        if (closingRaw instanceof admin.firestore.Timestamp) {
          closingMs = closingRaw.toMillis();
        }
        if (closingMs != null && nowMs >= closingMs) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Pickup window for an item has ended."
          );
        }

        const stock = Math.max(0, Math.floor((fd.stock as number) || 0));
        const reserved =
          Math.max(0, Math.floor((fd.reservedStock as number) || 0));
        const releaseQty = releaseQtyByFood.get(line.foodItemId) ?? 0;
        const available = stock - Math.max(0, reserved - releaseQty);
        if (available < line.quantity) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Not enough stock for one or more items."
          );
        }
      }

      for (const foodId of foodIds) {
        const foodSnap = foodSnaps.get(foodId);
        if (!foodSnap?.exists) continue;
        const fd = foodSnap.data()!;
        const reserved =
          Math.max(0, Math.floor((fd.reservedStock as number) || 0));
        const releaseQty = releaseQtyByFood.get(foodId) ?? 0;
        const newQty = newQtyByFood.get(foodId) ?? 0;
        tx.update(foodSnap.ref, {
          reservedStock: Math.max(0, reserved - releaseQty) + newQty,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      for (const hold of existingHolds) {
        tx.delete(hold.ref);
      }

      for (const line of mergedLines) {
        const resRef = db.collection("stock_reservations").doc();
        tx.set(resRef, {
          userId,
          foodItemId: line.foodItemId,
          reservedQuantity: line.quantity,
          reservationTimestamp:
            admin.firestore.FieldValue.serverTimestamp(),
          expirationTimestamp: expires,
        });
      }
    });

    return { ok: true, ttlMinutes, expiresAt: expires.toMillis() };
  }
);

/** Callable: release all active holds for the signed-in user (exit checkout / payment cancel). */
export const releaseStockReservations = functions.https.onCall(
  async (_data, context) => {
    const userId = requireAuthUid(context);
    const nowTs = admin.firestore.Timestamp.now();
    const snap = await db
      .collection("stock_reservations")
      .where("userId", "==", userId)
      .where("expirationTimestamp", ">", nowTs)
      .get();

    if (snap.empty) {
      return { released: 0 };
    }

    let released = 0;
    await db.runTransaction(async (tx) => {
      const holds: Array<{
        ref: admin.firestore.DocumentReference;
        foodItemId: string;
        quantity: number;
      }> = [];
      const releaseQtyByFood = new Map<string, number>();

      for (const doc of snap.docs) {
        const fresh = await tx.get(doc.ref);
        if (!fresh.exists) continue;
        const d = fresh.data()!;
        const foodItemId = d.foodItemId as string;
        const quantity = (d.reservedQuantity as number) || 0;
        if (!foodItemId || quantity < 1) continue;
        holds.push({ ref: doc.ref, foodItemId, quantity });
        releaseQtyByFood.set(
          foodItemId,
          (releaseQtyByFood.get(foodItemId) ?? 0) + quantity
        );
      }

      const foodSnaps = new Map<
        string,
        admin.firestore.DocumentSnapshot<admin.firestore.DocumentData>
      >();
      for (const foodId of releaseQtyByFood.keys()) {
        const foodRef = db.collection("food_items").doc(foodId);
        foodSnaps.set(foodId, await tx.get(foodRef));
      }

      for (const [foodId, qty] of releaseQtyByFood) {
        const foodSnap = foodSnaps.get(foodId);
        if (!foodSnap?.exists) continue;
        const fd = foodSnap.data()!;
        const r = (fd.reservedStock as number | undefined) ?? 0;
        tx.update(foodSnap.ref, {
          reservedStock: Math.max(0, r - qty),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      for (const hold of holds) {
        tx.delete(hold.ref);
        released++;
      }
    });

    return { released };
  }
);

/**
 * Pub/Sub: release holds past [expirationTimestamp].
 * Schedule in firebase.json or deploy with default every-2-minutes pattern.
 */
export const purgeExpiredStockReservations = functions
  .runWith({ timeoutSeconds: 120, memory: "256MB" })
  .pubsub.schedule("every 2 minutes")
  .onRun(async () => {
    const nowTs = admin.firestore.Timestamp.now();
    const query = db
      .collection("stock_reservations")
      .where("expirationTimestamp", "<=", nowTs)
      .orderBy("expirationTimestamp", "asc")
      .limit(400);

    const snap = await query.get();
    if (snap.empty) {
      return null;
    }

    await db.runTransaction(async (tx) => {
      const holds: Array<{
        ref: admin.firestore.DocumentReference;
        foodItemId: string;
        quantity: number;
      }> = [];
      const releaseQtyByFood = new Map<string, number>();

      for (const doc of snap.docs) {
        const fresh = await tx.get(doc.ref);
        if (!fresh.exists) continue;
        const d = fresh.data()!;
        const exp = d.expirationTimestamp as
          | admin.firestore.Timestamp
          | undefined;
        if (!exp || exp.toMillis() > nowTs.toMillis()) continue;
        const foodItemId = d.foodItemId as string;
        const quantity = (d.reservedQuantity as number) || 0;
        if (!foodItemId || quantity < 1) continue;
        holds.push({ ref: doc.ref, foodItemId, quantity });
        releaseQtyByFood.set(
          foodItemId,
          (releaseQtyByFood.get(foodItemId) ?? 0) + quantity
        );
      }

      const foodSnaps = new Map<
        string,
        admin.firestore.DocumentSnapshot<admin.firestore.DocumentData>
      >();
      for (const foodId of releaseQtyByFood.keys()) {
        const foodRef = db.collection("food_items").doc(foodId);
        foodSnaps.set(foodId, await tx.get(foodRef));
      }

      for (const [foodId, qty] of releaseQtyByFood) {
        const foodSnap = foodSnaps.get(foodId);
        if (!foodSnap?.exists) continue;
        const fd = foodSnap.data()!;
        const r = (fd.reservedStock as number | undefined) ?? 0;
        tx.update(foodSnap.ref, {
          reservedStock: Math.max(0, r - qty),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      for (const hold of holds) {
        tx.delete(hold.ref);
      }
    });

    return null;
  });

/**
 * Callable: create PaymentIntent for MYR checkout.
 * Config (set via CLI, never commit):
 *   firebase functions:config:set stripe.secret="sk_test_..."
 */
export const createPaymentIntent = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in to pay."
      );
    }

    const raw = data?.amount;
    const amount =
      typeof raw === "number"
        ? Math.floor(raw)
        : typeof raw === "string"
          ? parseInt(raw, 10)
          : NaN;

    if (!Number.isFinite(amount) || amount < 1) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "amount must be a positive integer (smallest currency unit, e.g. sen for MYR)."
      );
    }

    const secret = functions.config().stripe?.secret as string | undefined;
    if (!secret) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Stripe is not configured. Set stripe.secret with firebase functions:config:set."
      );
    }

    const stripe = new Stripe(secret);

    // Card only — avoids Apple Pay on iOS unless the app sets
    // Stripe.merchantIdentifier + Stripe Dashboard Apple Pay; otherwise the
    // Payment Sheet native layer can crash ("Lost connection to device").
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: "myr",
      payment_method_types: ["card"],
      metadata: {
        firebaseUid: context.auth.uid,
      },
    });

    const clientSecret = paymentIntent.client_secret;
    if (!clientSecret) {
      throw new functions.https.HttpsError(
        "internal",
        "Stripe did not return a client secret."
      );
    }

    return { clientSecret };
  }
);
