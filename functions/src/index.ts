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

/** kg CO₂e per rescued portion (quantity = meal); thesis constant (Too Good To Go–style factor). */
const CO2E_KG_PER_MEAL = 2.7;

/** Firestore occasionally stores array-shaped maps keyed by "0","1",… — normalize for iteration. */
function normalizeOrderItemsArray(items: unknown): unknown[] {
  if (Array.isArray(items)) {
    return items;
  }
  if (items != null && typeof items === "object") {
    const o = items as Record<string, unknown>;
    const keys = Object.keys(o);
    const allNumericKeys =
      keys.length > 0 && keys.every((k) => /^\d+$/.test(k));
    if (allNumericKeys) {
      return [...keys]
        .sort((a, b) => Number(a) - Number(b))
        .map((k) => o[k]);
    }
  }
  return [];
}

function coerceFiniteNumber(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (trimmed === "") return undefined;
    const x = Number(trimmed.replace(",", "."));
    if (Number.isFinite(x)) {
      return x;
    }
  }
  const maybeProto = value as { toNumber?: () => number } | null;
  if (
    maybeProto != null &&
    typeof maybeProto === "object" &&
    typeof maybeProto.toNumber === "function"
  ) {
    try {
      const x = maybeProto.toNumber();
      if (Number.isFinite(x)) {
        return x;
      }
    } catch {
      //
    }
  }
  return undefined;
}

/** True if checkout was recorded as paid (Stripe-paid orders always have paidAt server timestamp). */
function paymentLooksPaidForImpact(after: Record<string, unknown>): boolean {
  const payRaw =
    typeof after.paymentStatus === "string" ? after.paymentStatus : "";
  const pay = payRaw.toLowerCase().trim();
  if (pay === "paid" || pay === "mockpaid") return true;

  const paidAt = after.paidAt;
  const hasPaidAt = paidAt != null && `${paidAt}` !== "";
  if (!hasPaidAt) return false;

  if (
    pay === "pending" ||
    pay === "failed" ||
    pay === "canceled" ||
    pay === "cancelled"
  ) {
    return false;
  }

  return true;
}

function readTotalSavings(after: Record<string, unknown>): number {
  return coerceFiniteNumber(after.totalSavings) ?? 0;
}

function readSubtotal(after: Record<string, unknown>): number {
  return coerceFiniteNumber(after.subtotal) ?? 0;
}

function lineMealQuantity(line: Record<string, unknown>): number {
  const qtyKeys = ["quantity", "qty", "mealCount"];
  let best = 0;
  for (const k of qtyKeys) {
    const n = coerceFiniteNumber(line[k]);
    if (n === undefined || n < 1) continue;
    const floored = Math.floor(n);
    if (floored > best) best = floored;
  }
  return best;
}

function sumMealsFromOrderItems(items: unknown): number {
  const arr = normalizeOrderItemsArray(items);
  let sum = 0;
  for (const raw of arr) {
    if (typeof raw !== "object" || raw === null) continue;
    const q = lineMealQuantity(raw as Record<string, unknown>);
    if (q >= 1) sum += q;
  }
  return sum;
}

function normalizedOrderStatus(
  doc: admin.firestore.DocumentData | Record<string, unknown>
): string {
  const plain = doc as Record<string, unknown>;
  const orderStatusRaw =
    typeof plain.orderStatus === "string"
      ? plain.orderStatus.trim()
      : typeof plain.status === "string"
        ? String(plain.status).trim()
        : "";
  return orderStatusRaw.toLowerCase();
}

/**
 * Writes under the real nested map [`impactData`] (Flutter expects `impactData.mealsSaved`, etc.).
 * Do NOT use top-level dotted keys with `set(..., { merge: true })`: Firestore stores them as literal
 * field names (`"impactData.mealsSaved"` as one key), so clients reading `impactData` see zeros).
 * Nested merge preserves other `impactData` fields while applying increments — see Firebase SO #70183767.
 */
function impactIncrementsNestedPayload(
  meals: number,
  moneyAmount: number,
  co2Delta: number
) {
  return {
    impactData: {
      mealsSaved: admin.firestore.FieldValue.increment(meals),
      moneySaved: admin.firestore.FieldValue.increment(moneyAmount),
      co2Reduced: admin.firestore.FieldValue.increment(co2Delta),
      ordersCompleted: admin.firestore.FieldValue.increment(1),
    },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

/**
 * Idempotent transaction: first time an order transitions to paid `completed`.
 * Buyer gets savings total (`totalSavings`) while merchant gets earned subtotal (`subtotal`).
 * Duplicate triggers or concurrent updates abort when `sustainabilityImpactApplied` is set.
 *
 * Logs: impact_applied_completed_order_buyer_merchant, impact_skip_already_applied, etc.
 * Deploy after changes: firebase deploy --only functions:applyBuyerSustainabilityOnOrderCompleted
 */
export const applyBuyerSustainabilityOnOrderCompleted = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const orderId = context.params.orderId as string;
    try {
      const before = change.before.data();
      const after = change.after.data();
      if (!before || !after) return null;

      const afterPlain = after as Record<string, unknown>;
      const beforePlain = before as Record<string, unknown>;

      const afterOrderStatus = normalizedOrderStatus(afterPlain);
      const beforeOrderStatus = normalizedOrderStatus(beforePlain);

      if (beforeOrderStatus === "completed") return null;
      if (afterOrderStatus !== "completed") return null;

      if (
        typeof afterPlain.sustainabilityImpactApplied === "boolean" &&
        afterPlain.sustainabilityImpactApplied === true
      ) {
        functions.logger.debug("impact_skip_after_snapshot_already_applied", {
          orderId,
        });
        return null;
      }

      type ImpactTxnResult =
        | { outcome: "skip"; reason: string; detail?: Record<string, unknown> }
        | {
            outcome: "applied";
            buyerId: string;
            merchantUid: string | null;
            mergedBuyerMerchant: boolean;
            meals: number;
            buyerMoneyAmount: number;
            merchantMoneyAmount: number;
            co2Delta: number;
          };

      const txResult = await db.runTransaction(async (tx): Promise<ImpactTxnResult> => {
        const orderRef = db.collection("orders").doc(orderId);
        const orderSnap = await tx.get(orderRef);
        const data = orderSnap.data();
        if (!data) {
          return { outcome: "skip", reason: "missing_order_doc" };
        }

        const d = data as Record<string, unknown>;
        if (
          typeof d.sustainabilityImpactApplied === "boolean" &&
          d.sustainabilityImpactApplied === true
        ) {
          return { outcome: "skip", reason: "already_applied" };
        }

        const statusInTx = normalizedOrderStatus(d);
        if (statusInTx !== "completed") {
          return {
            outcome: "skip",
            reason: "not_completed_in_tx",
            detail: { statusInTx },
          };
        }

        if (!paymentLooksPaidForImpact(d)) {
          return {
            outcome: "skip",
            reason: "unpaid_in_tx",
            detail: {
              paymentStatus: d.paymentStatus ?? null,
            },
          };
        }

        const meals = sumMealsFromOrderItems(d.items);
        if (meals < 1) {
          return {
            outcome: "skip",
            reason: "zero_meals_in_tx",
            detail: { itemsType: d.items === null ? "null" : typeof d.items },
          };
        }

        const buyerIdRaw = typeof d.userId === "string" ? d.userId.trim() : "";
        if (!buyerIdRaw) {
          return { outcome: "skip", reason: "missing_user_id_in_tx" };
        }

        const merchantUidRaw =
          typeof d.merchantId === "string" ? d.merchantId.trim() : "";

        const totalSavings = readTotalSavings(d);
        const subtotal = readSubtotal(d);
        const co2Delta = meals * CO2E_KG_PER_MEAL;
        const buyerPayload = impactIncrementsNestedPayload(
          meals,
          totalSavings,
          co2Delta
        );
        const merchantPayload = impactIncrementsNestedPayload(
          meals,
          subtotal,
          co2Delta
        );

        tx.update(orderRef, {
          sustainabilityImpactApplied: true,
          sustainabilityImpactAppliedAt:
            admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const buyerRef = db.collection("users").doc(buyerIdRaw);
        const sameBuyerAndMerchant =
          merchantUidRaw !== "" && merchantUidRaw === buyerIdRaw;
        if (sameBuyerAndMerchant) {
          tx.set(buyerRef, buyerPayload, { merge: true });
          return {
            outcome: "applied",
            buyerId: buyerIdRaw,
            merchantUid: merchantUidRaw || null,
            mergedBuyerMerchant: true,
            meals,
            buyerMoneyAmount: totalSavings,
            merchantMoneyAmount: subtotal,
            co2Delta,
          };
        }

        tx.set(buyerRef, buyerPayload, { merge: true });

        if (!merchantUidRaw) {
          return {
            outcome: "applied",
            buyerId: buyerIdRaw,
            merchantUid: null,
            mergedBuyerMerchant: false,
            meals,
            buyerMoneyAmount: totalSavings,
            merchantMoneyAmount: subtotal,
            co2Delta,
          };
        }

        tx.set(db.collection("users").doc(merchantUidRaw), merchantPayload, {
          merge: true,
        });
        return {
          outcome: "applied",
          buyerId: buyerIdRaw,
          merchantUid: merchantUidRaw,
          mergedBuyerMerchant: false,
          meals,
          buyerMoneyAmount: totalSavings,
          merchantMoneyAmount: subtotal,
          co2Delta,
        };
      });

      if (txResult.outcome === "applied") {
        const a = txResult;
        if (a.mergedBuyerMerchant) {
          functions.logger.info("impact_applied_completed_order_buyer_equals_merchant", {
            orderId,
            userId: a.buyerId,
            meals: a.meals,
            buyerMoneyApplied: a.buyerMoneyAmount,
            merchantMoneyApplied: a.merchantMoneyAmount,
            co2Delta: a.co2Delta,
          });
        } else if (a.merchantUid) {
          functions.logger.info("impact_applied_completed_order_buyer_and_merchant", {
            orderId,
            buyerId: a.buyerId,
            merchantUid: a.merchantUid,
            meals: a.meals,
            buyerMoneyApplied: a.buyerMoneyAmount,
            merchantMoneyApplied: a.merchantMoneyAmount,
            co2Delta: a.co2Delta,
          });
        } else {
          functions.logger.warn("impact_applied_buyer_only_missing_merchantId", {
            orderId,
            buyerId: a.buyerId,
            meals: a.meals,
            buyerMoneyApplied: a.buyerMoneyAmount,
            merchantMoneyApplied: a.merchantMoneyAmount,
            co2Delta: a.co2Delta,
          });
        }
      } else {
        const s = txResult;
        if (s.reason === "already_applied") {
          functions.logger.debug("impact_skip_already_applied_tx", {
            orderId,
          });
        } else if (s.reason === "missing_order_doc") {
          functions.logger.warn("impact_skip_missing_order_in_tx", { orderId });
        } else {
          functions.logger.warn(`impact_skip_${s.reason}`, {
            orderId,
            ...(s.detail ?? {}),
          });
        }
      }

      return null;
    } catch (e) {
      functions.logger.error("impact_apply_failed", {
        orderId,
        message: String(e),
      });
      throw e;
    }
  });

function normalizeOrderStatusForCancellation(data: unknown): string {
  if (!data || typeof data !== "object") return "";
  const d = data as Record<string, unknown>;
  const raw =
    typeof d.orderStatus === "string"
      ? d.orderStatus
      : typeof d.status === "string"
        ? String(d.status)
        : "";
  return raw.trim().toLowerCase();
}

function lineFoodIdQty(line: Record<string, unknown>): {
  id: string;
  qty: number;
} | null {
  const fi = line.foodItem as Record<string, unknown> | undefined;
  let id = "";
  if (fi && typeof fi.id === "string") {
    id = fi.id.trim();
  }
  if (!id) {
    const alt = line.foodItemId;
    id = typeof alt === "string" ? alt.trim() : "";
  }
  let q = NaN;
  const rawQty = line.quantity;
  if (typeof rawQty === "number") {
    q = rawQty;
  } else if (rawQty !== undefined && rawQty !== null) {
    q = parseInt(String(rawQty), 10);
  }
  const qty = Math.max(1, Math.floor(Number.isFinite(q) ? q : 0));
  if (!id || qty < 1) return null;
  return { id, qty };
}

function refundStatusNormalized(v: unknown): string {
  if (typeof v !== "string") return "none";
  return v.trim().toLowerCase() || "none";
}

/**
 * On transition to cancelled (Firestore `orderStatus`): restore surplus stock when
 * the order was cancelled from `pending`, and card refunds via Stripe when
 * `stripePaymentIntentId` is present (`pi_…`).
 */
export const reconcileCancelledPaidOrderSideEffects = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const orderId = context.params.orderId as string;
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) {
      return null;
    }

    const beforeStat = normalizeOrderStatusForCancellation(before);
    const afterStat = normalizeOrderStatusForCancellation(after);
    if (beforeStat === "cancelled") {
      return null;
    }
    if (afterStat !== "cancelled") {
      return null;
    }

    const prevPending = beforeStat === "pending";
    const orderRef = db.collection("orders").doc(orderId);

    if (prevPending && after.stockRestoredFromCancellation !== true) {
      const arr = normalizeOrderItemsArray(after.items);
      const lines = arr
        .filter(
          (x): x is Record<string, unknown> =>
            typeof x === "object" && x !== null
        )
        .map(lineFoodIdQty)
        .filter((x): x is { id: string; qty: number } => x != null);

      if (lines.length > 0) {
        try {
          await db.runTransaction(async (tx) => {
            for (const { id: foodItemId, qty } of lines) {
              const ref = db.collection("food_items").doc(foodItemId);
              const snap = await tx.get(ref);
              if (!snap.exists) {
                functions.logger.warn("cancel_restore_skip_missing_food", {
                  orderId,
                  foodItemId,
                });
                continue;
              }
              const fd = snap.data()!;
              const prevStock =
                typeof fd.stock === "number" && Number.isFinite(fd.stock)
                  ? Math.floor(fd.stock)
                  : 0;
              tx.update(ref, {
                stock: prevStock + qty,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
          });

          await orderRef.set(
            {
              stockRestoredFromCancellation: true,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );

          functions.logger.info("cancel_stock_restored", { orderId, lines });
        } catch (e) {
          functions.logger.error("cancel_stock_restore_failed", {
            orderId,
            message: String(e),
          });
        }
      } else {
        functions.logger.warn("cancel_restore_no_item_lines", { orderId });
        await orderRef.set(
          {
            stockRestoredFromCancellation: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    }

    const refundSt = refundStatusNormalized(after.paymentRefundStatus);
    const terminalRefund = ["succeeded", "failed", "notApplicable"].includes(
      refundSt
    );
    if (terminalRefund) {
      return null;
    }

    const pi =
      typeof after.stripePaymentIntentId === "string"
        ? after.stripePaymentIntentId.trim()
        : "";

    if (!pi.startsWith("pi_")) {
      await orderRef.set(
        {
          paymentRefundStatus: "notApplicable",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      functions.logger.info("cancel_refund_not_applicable", { orderId });
      return null;
    }

    const secret = functions.config().stripe?.secret as string | undefined;
    if (!secret) {
      functions.logger.warn("cancel_refund_skip_no_stripe_secret", {
        orderId,
      });
      await orderRef.set(
        {
          paymentRefundStatus: "failed",
          paymentRefundNote:
            "Stripe secret not configured; set stripe.secret via Firebase config.",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return null;
    }

    await orderRef.set(
      {
        paymentRefundStatus: "pending",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const stripe = new Stripe(secret);

    try {
      const rf = await stripe.refunds.create(
        { payment_intent: pi },
        { idempotencyKey: `cancel_refund_${orderId}` }
      );

      const rfStatus =
        typeof rf.status === "string" ? rf.status.toLowerCase() : "";
      const rfSucceeded = rfStatus === "succeeded";
      const rfFailed = rfStatus === "failed" || rfStatus === "canceled";
      let note =
        typeof (rf as { failure_reason?: string }).failure_reason === "string"
          ? (rf as { failure_reason: string }).failure_reason
          : undefined;
      if (rfFailed && !note) note = rfStatus;

      let payRefund: "succeeded" | "pending" | "failed";
      if (rfSucceeded) {
        payRefund = "succeeded";
      } else if (rfFailed) {
        payRefund = "failed";
      } else {
        payRefund = "pending";
      }

      await orderRef.set(
        {
          paymentRefundStatus: payRefund,
          stripeRefundId: rf.id,
          ...(note ? { paymentRefundNote: note } : {}),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      functions.logger.info("cancel_refund_ok", {
        orderId,
        stripeRefundStatus: rf.status,
      });
    } catch (e) {
      const msg = String(e);
      functions.logger.error("cancel_refund_failed", { orderId, message: msg });
      await orderRef.set(
        {
          paymentRefundStatus: "failed",
          paymentRefundNote: msg.slice(0, 500),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    return null;
  });
