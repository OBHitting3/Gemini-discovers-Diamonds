// Dead-Letter Queue for failed email deliveries and webhook processing
// Per Master System Document OODA engineering spec

const fs = require('fs');
const path = require('path');

const DLQ_FILE = path.join(__dirname, '..', 'data', 'dead-letter-queue.json');
const MAX_RETRIES = 3;

function ensureDataDir() {
  const dir = path.dirname(DLQ_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function loadQueue() {
  ensureDataDir();
  if (!fs.existsSync(DLQ_FILE)) return [];
  return JSON.parse(fs.readFileSync(DLQ_FILE, 'utf-8'));
}

function saveQueue(queue) {
  ensureDataDir();
  fs.writeFileSync(DLQ_FILE, JSON.stringify(queue, null, 2));
}

const deadLetterQueue = {
  // Add a failed item to the DLQ
  enqueue(type, payload, error) {
    const queue = loadQueue();
    const entry = {
      id: `dlq_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      type, // 'email_delivery', 'webhook_processing', 'stripe_event'
      payload,
      error: error.message || String(error),
      retryCount: 0,
      maxRetries: MAX_RETRIES,
      createdAt: new Date().toISOString(),
      lastRetryAt: null,
      status: 'pending', // pending, retrying, exhausted, resolved
    };
    queue.push(entry);
    saveQueue(queue);
    console.error(`[DLQ] Enqueued ${type}: ${entry.id} - ${error.message || error}`);
    return entry;
  },

  // Get all pending items for retry
  getPending() {
    const queue = loadQueue();
    return queue.filter(e => e.status === 'pending' || e.status === 'retrying');
  },

  // Mark item as being retried
  markRetrying(id) {
    const queue = loadQueue();
    const item = queue.find(e => e.id === id);
    if (item) {
      item.retryCount += 1;
      item.lastRetryAt = new Date().toISOString();
      if (item.retryCount >= item.maxRetries) {
        item.status = 'exhausted';
      } else {
        item.status = 'retrying';
      }
      saveQueue(queue);
    }
    return item;
  },

  // Mark item as resolved
  markResolved(id) {
    const queue = loadQueue();
    const item = queue.find(e => e.id === id);
    if (item) {
      item.status = 'resolved';
      item.resolvedAt = new Date().toISOString();
      saveQueue(queue);
    }
    return item;
  },

  // Get DLQ stats for Synaptic Relay dashboard
  getStats() {
    const queue = loadQueue();
    return {
      total: queue.length,
      pending: queue.filter(e => e.status === 'pending').length,
      retrying: queue.filter(e => e.status === 'retrying').length,
      exhausted: queue.filter(e => e.status === 'exhausted').length,
      resolved: queue.filter(e => e.status === 'resolved').length,
    };
  },

  // Get all items (for admin dashboard)
  getAll() {
    return loadQueue();
  },
};

module.exports = { deadLetterQueue };
