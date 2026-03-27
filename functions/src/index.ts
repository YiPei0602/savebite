import * as functions from "firebase-functions";
import Stripe from "stripe";

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
