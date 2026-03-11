// Synaptic Relay - Engineering Observability System
// Per Master System Document OODA engineering spec

const fs = require('fs');
const path = require('path');

const EVENTS_FILE = path.join(__dirname, '..', 'data', 'synaptic-events.json');
const ALERTS_FILE = path.join(__dirname, '..', 'data', 'pain-line-alerts.json');

function ensureDataDir() {
  const dir = path.dirname(EVENTS_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function loadJson(file) {
  ensureDataDir();
  if (!fs.existsSync(file)) return [];
  return JSON.parse(fs.readFileSync(file, 'utf-8'));
}

function saveJson(file, data) {
  ensureDataDir();
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

// Pain Line thresholds - triggers alerts when crossed
const PAIN_LINES = {
  email_delivery_failure_rate: 0.05,  // > 5% failure rate
  stripe_payment_failure_rate: 0.02,  // > 2% failure rate
  episode_buffer_minimum: 7,           // < 7 episodes buffered
  dlq_pending_count: 5,               // > 5 items stuck in DLQ
};

const synapticRelay = {
  // Log a system event
  logEvent(category, action, data = {}) {
    const events = loadJson(EVENTS_FILE);
    const event = {
      id: `evt_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      category, // 'email', 'stripe', 'content', 'auth', 'system'
      action,
      data,
      timestamp: new Date().toISOString(),
    };
    events.push(event);
    // Keep last 10000 events
    if (events.length > 10000) events.splice(0, events.length - 10000);
    saveJson(EVENTS_FILE, events);
    return event;
  },

  // Check a value against its Pain Line threshold and alert if crossed
  checkPainLine(metric, value) {
    const threshold = PAIN_LINES[metric];
    if (threshold === undefined) return null;

    let triggered = false;
    if (metric === 'episode_buffer_minimum') {
      triggered = value < threshold;
    } else {
      triggered = value > threshold;
    }

    if (triggered) {
      const alert = {
        id: `alert_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
        metric,
        value,
        threshold,
        severity: 'critical',
        message: `Pain Line crossed: ${metric} = ${value} (threshold: ${threshold})`,
        timestamp: new Date().toISOString(),
        acknowledged: false,
      };
      const alerts = loadJson(ALERTS_FILE);
      alerts.push(alert);
      saveJson(ALERTS_FILE, alerts);
      console.error(`[PAIN LINE] ${alert.message}`);
      return alert;
    }
    return null;
  },

  // Get recent events filtered by category
  getEvents(category = null, limit = 100) {
    const events = loadJson(EVENTS_FILE);
    const filtered = category ? events.filter(e => e.category === category) : events;
    return filtered.slice(-limit);
  },

  // Get active (unacknowledged) alerts
  getActiveAlerts() {
    const alerts = loadJson(ALERTS_FILE);
    return alerts.filter(a => !a.acknowledged);
  },

  // Acknowledge an alert
  acknowledgeAlert(id) {
    const alerts = loadJson(ALERTS_FILE);
    const alert = alerts.find(a => a.id === id);
    if (alert) {
      alert.acknowledged = true;
      alert.acknowledgedAt = new Date().toISOString();
      saveJson(ALERTS_FILE, alerts);
    }
    return alert;
  },

  // Get system health dashboard data
  getDashboard() {
    const events = loadJson(EVENTS_FILE);
    const alerts = loadJson(ALERTS_FILE);
    const now = Date.now();
    const last24h = events.filter(e => now - new Date(e.timestamp).getTime() < 86400000);

    const emailEvents = last24h.filter(e => e.category === 'email');
    const emailFailures = emailEvents.filter(e => e.action === 'delivery_failed');
    const stripeEvents = last24h.filter(e => e.category === 'stripe');
    const stripeFailures = stripeEvents.filter(e => e.action === 'payment_failed');

    return {
      uptime: process.uptime(),
      last24h: {
        totalEvents: last24h.length,
        emailsSent: emailEvents.filter(e => e.action === 'delivery_success').length,
        emailsFailed: emailFailures.length,
        emailFailureRate: emailEvents.length > 0 ? emailFailures.length / emailEvents.length : 0,
        paymentsProcessed: stripeEvents.filter(e => e.action === 'payment_success').length,
        paymentsFailed: stripeFailures.length,
        paymentFailureRate: stripeEvents.length > 0 ? stripeFailures.length / stripeEvents.length : 0,
      },
      activeAlerts: alerts.filter(a => !a.acknowledged).length,
      totalAlerts: alerts.length,
    };
  },
};

module.exports = { synapticRelay, PAIN_LINES };
