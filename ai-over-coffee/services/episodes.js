// Episode content store (file-based for MVP)

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { assertions } = require('../config/assertions');

const EPISODES_FILE = path.join(__dirname, '..', 'data', 'episodes.json');

function ensureDataDir() {
  const dir = path.dirname(EPISODES_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function loadEpisodes() {
  ensureDataDir();
  if (!fs.existsSync(EPISODES_FILE)) return [];
  return JSON.parse(fs.readFileSync(EPISODES_FILE, 'utf-8'));
}

function saveEpisodes(episodes) {
  ensureDataDir();
  fs.writeFileSync(EPISODES_FILE, JSON.stringify(episodes, null, 2));
}

const episodeStore = {
  create({ title, teaser, tier, videoUrl, thumbnailUrl, subtitleUrl, durationSeconds, emailSubject, publishDate }) {
    const episode = {
      id: uuidv4(),
      title,
      teaser: teaser || '',
      tier, // 'morning_coffee' or 'nightcap'
      videoUrl,
      thumbnailUrl: thumbnailUrl || '',
      subtitleUrl: subtitleUrl || '',
      durationSeconds: durationSeconds || 0,
      emailSubject: emailSubject || title,
      publishDate, // ISO date string YYYY-MM-DD
      qcPassed: false,
      published: false,
      createdAt: new Date().toISOString(),
    };

    // A1: video URL must exist
    assertions.episodeFileExists(episode);

    const episodes = loadEpisodes();
    episodes.push(episode);
    saveEpisodes(episodes);
    return episode;
  },

  markQCPassed(episodeId) {
    const episodes = loadEpisodes();
    const ep = episodes.find(e => e.id === episodeId);
    if (ep) {
      ep.qcPassed = true;
      ep.qcPassedAt = new Date().toISOString();
      saveEpisodes(episodes);
    }
    return ep;
  },

  publish(episodeId) {
    const episodes = loadEpisodes();
    const ep = episodes.find(e => e.id === episodeId);
    if (ep) {
      // A8: must pass QC first
      assertions.episodeQCPassed(ep);
      ep.published = true;
      ep.publishedAt = new Date().toISOString();
      saveEpisodes(episodes);
    }
    return ep;
  },

  getById(id) {
    return loadEpisodes().find(e => e.id === id);
  },

  // Get published episodes for a tier (for dashboard)
  getPublishedForTier(tier) {
    return loadEpisodes()
      .filter(e => e.published && e.tier === tier)
      .sort((a, b) => new Date(a.publishDate) - new Date(b.publishDate));
  },

  // Get buffer count (QC'd but not yet published)
  getBufferCount(tier) {
    return loadEpisodes()
      .filter(e => e.qcPassed && !e.published && e.tier === tier)
      .length;
  },

  // Get all episodes (admin view)
  getAll() {
    return loadEpisodes().sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  },

  // Get content calendar view
  getCalendar() {
    const episodes = loadEpisodes();
    const calendar = {};
    for (const ep of episodes) {
      const date = ep.publishDate || 'unscheduled';
      if (!calendar[date]) calendar[date] = [];
      calendar[date].push({
        id: ep.id,
        title: ep.title,
        tier: ep.tier,
        qcPassed: ep.qcPassed,
        published: ep.published,
      });
    }
    return calendar;
  },

  update(episodeId, updates) {
    const episodes = loadEpisodes();
    const ep = episodes.find(e => e.id === episodeId);
    if (ep) {
      Object.assign(ep, updates, { updatedAt: new Date().toISOString() });
      saveEpisodes(episodes);
    }
    return ep;
  },
};

module.exports = { episodeStore };
