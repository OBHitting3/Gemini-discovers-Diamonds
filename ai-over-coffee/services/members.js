// Member data store (file-based for MVP, swap for DB later)

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const MEMBERS_FILE = path.join(__dirname, '..', 'data', 'members.json');

function ensureDataDir() {
  const dir = path.dirname(MEMBERS_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function loadMembers() {
  ensureDataDir();
  if (!fs.existsSync(MEMBERS_FILE)) return [];
  return JSON.parse(fs.readFileSync(MEMBERS_FILE, 'utf-8'));
}

function saveMembers(members) {
  ensureDataDir();
  fs.writeFileSync(MEMBERS_FILE, JSON.stringify(members, null, 2));
}

const memberStore = {
  create({ email, firstName, tier, stripeCustomerId, stripeSubscriptionId }) {
    const members = loadMembers();
    const member = {
      id: uuidv4(),
      email,
      firstName,
      tier,
      morningCoffeeAccess: tier === 'nightcap' || tier === 'morning_coffee',
      nightcapAccess: tier === 'nightcap',
      stripeCustomerId,
      stripeSubscriptionId,
      watchedEpisodes: [],
      status: 'active',
      createdAt: new Date().toISOString(),
    };
    members.push(member);
    saveMembers(members);
    return member;
  },

  getByEmail(email) {
    return loadMembers().find(m => m.email === email && m.status === 'active');
  },

  getByStripeCustomerId(customerId) {
    return loadMembers().find(m => m.stripeCustomerId === customerId);
  },

  getByStripeSubscriptionId(subscriptionId) {
    return loadMembers().find(m => m.stripeSubscriptionId === subscriptionId);
  },

  getById(id) {
    return loadMembers().find(m => m.id === id);
  },

  markEpisodeWatched(memberId, episodeId) {
    const members = loadMembers();
    const member = members.find(m => m.id === memberId);
    if (member && !member.watchedEpisodes.includes(episodeId)) {
      member.watchedEpisodes.push(episodeId);
      saveMembers(members);
    }
    return member;
  },

  cancel(stripeSubscriptionId) {
    const members = loadMembers();
    const member = members.find(m => m.stripeSubscriptionId === stripeSubscriptionId);
    if (member) {
      member.status = 'cancelled';
      member.cancelledAt = new Date().toISOString();
      saveMembers(members);
    }
    return member;
  },

  getAll() {
    return loadMembers().filter(m => m.status === 'active');
  },

  getStats() {
    const members = loadMembers();
    const active = members.filter(m => m.status === 'active');
    return {
      totalActive: active.length,
      morningCoffee: active.filter(m => m.tier === 'morning_coffee').length,
      nightcap: active.filter(m => m.tier === 'nightcap').length,
      mrr: active.reduce((sum, m) => {
        return sum + (m.tier === 'nightcap' ? 4900 : 2500);
      }, 0) / 100,
      cancelled: members.filter(m => m.status === 'cancelled').length,
    };
  },
};

module.exports = { memberStore };
