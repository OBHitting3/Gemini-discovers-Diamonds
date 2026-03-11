// Stripe Checkout Routes

const express = require('express');
const router = express.Router();
const { TIERS } = require('../config/tiers');
const { assertions } = require('../config/assertions');
const { synapticRelay } = require('../services/synaptic-relay');

router.post('/create-checkout-session', express.json(), async (req, res) => {
  try {
    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    const { tier: tierId, email } = req.body;

    const tier = TIERS[tierId];
    if (!tier) {
      return res.status(400).json({ error: 'Invalid tier' });
    }

    // A4: Stripe price must be configured
    assertions.stripePriceConfigured(tier);

    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      payment_method_types: ['card'],
      customer_email: email,
      line_items: [{
        price: tier.stripePriceId,
        quantity: 1,
      }],
      success_url: `${process.env.BASE_URL}/welcome?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.BASE_URL}/#pricing`,
      metadata: { tier: tierId },
    });

    synapticRelay.logEvent('stripe', 'checkout_created', { tier: tierId, email });
    res.json({ url: session.url });
  } catch (err) {
    synapticRelay.logEvent('stripe', 'checkout_failed', { error: err.message });
    res.status(500).json({ error: err.message });
  }
});

// Stripe webhook handler
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    synapticRelay.logEvent('stripe', 'webhook_invalid', { error: err.message });
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  const { memberStore } = require('../services/members');
  const { brevo } = require('../services/brevo');

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object;
      const tierId = session.metadata.tier;
      const tier = TIERS[tierId];

      const member = memberStore.create({
        email: session.customer_email,
        firstName: session.customer_details?.name?.split(' ')[0] || 'Friend',
        tier: tierId,
        stripeCustomerId: session.customer,
        stripeSubscriptionId: session.subscription,
      });

      // Add to Brevo lists
      try {
        await brevo.addContact(member.email, member.firstName, tier);
        await brevo.sendWelcomeEmail(member.email, member.firstName, tier);
        synapticRelay.logEvent('email', 'welcome_sent', { email: member.email, tier: tierId });
      } catch (err) {
        synapticRelay.logEvent('email', 'welcome_failed', { email: member.email, error: err.message });
      }

      synapticRelay.logEvent('stripe', 'payment_success', { email: member.email, tier: tierId });
      break;
    }

    case 'invoice.payment_failed': {
      const invoice = event.data.object;
      const member = memberStore.getByStripeCustomerId(invoice.customer);
      synapticRelay.logEvent('stripe', 'payment_failed', {
        email: member?.email,
        customerId: invoice.customer,
      });
      // Pain Line check
      const stats = memberStore.getStats();
      if (stats.totalActive > 0) {
        synapticRelay.checkPainLine('stripe_payment_failure_rate',
          stats.cancelled / (stats.totalActive + stats.cancelled));
      }
      break;
    }

    case 'customer.subscription.deleted': {
      const subscription = event.data.object;
      const member = memberStore.cancel(subscription.id);
      if (member) {
        try {
          await brevo.removeContact(member.email);
        } catch (err) {
          synapticRelay.logEvent('email', 'remove_contact_failed', { error: err.message });
        }
        synapticRelay.logEvent('stripe', 'subscription_cancelled', { email: member.email });
      }
      break;
    }
  }

  res.json({ received: true });
});

module.exports = router;
