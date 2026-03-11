// Admin Routes - Content Calendar, Upload, Monitoring

const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { requireAdmin } = require('../middleware/auth');
const { episodeStore } = require('../services/episodes');
const { memberStore } = require('../services/members');
const { synapticRelay } = require('../services/synaptic-relay');
const { deadLetterQueue } = require('../services/dead-letter-queue');
const { assertions } = require('../config/assertions');

// File upload config
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const name = file.originalname.replace(ext, '').replace(/[^a-zA-Z0-9_-]/g, '_');
    cb(null, `${Date.now()}_${name}${ext}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 500 * 1024 * 1024 } }); // 500MB max

// Admin login (simple passphrase for MVP)
router.get('/admin/login', (req, res) => {
  res.send(`<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Admin - AI Over Coffee</title>
<link rel="stylesheet" href="/css/style.css"></head>
<body class="login-page"><div class="login-container">
  <h1>Admin Access</h1>
  <form method="POST" action="/admin/login">
    <label for="passphrase">Passphrase</label>
    <input type="password" id="passphrase" name="passphrase" required>
    <button type="submit">Enter</button>
  </form>
</div></body></html>`);
});

router.post('/admin/login', express.urlencoded({ extended: true }), (req, res) => {
  if (req.body.passphrase === (process.env.ADMIN_PASSPHRASE || 'ironforge2026')) {
    req.session.isAdmin = true;
    res.redirect('/admin');
  } else {
    res.status(401).send('Invalid passphrase');
  }
});

// Admin dashboard
router.get('/admin', requireAdmin, (req, res) => {
  const episodes = episodeStore.getAll();
  const stats = memberStore.getStats();
  const mcBuffer = episodeStore.getBufferCount('morning_coffee');
  const ncBuffer = episodeStore.getBufferCount('nightcap');
  const health = synapticRelay.getDashboard();
  const dlqStats = deadLetterQueue.getStats();
  const alerts = synapticRelay.getActiveAlerts();

  // Pain Line checks
  synapticRelay.checkPainLine('episode_buffer_minimum', mcBuffer);
  synapticRelay.checkPainLine('episode_buffer_minimum', ncBuffer);
  synapticRelay.checkPainLine('dlq_pending_count', dlqStats.pending);

  res.send(buildAdminDashboard({ episodes, stats, mcBuffer, ncBuffer, health, dlqStats, alerts }));
});

// Content Calendar
router.get('/admin/calendar', requireAdmin, (req, res) => {
  const calendar = episodeStore.getCalendar();
  res.send(buildCalendarPage(calendar));
});

// Upload episode form
router.get('/admin/upload', requireAdmin, (req, res) => {
  res.send(buildUploadPage());
});

// Handle episode upload
router.post('/admin/upload', requireAdmin, upload.fields([
  { name: 'video', maxCount: 1 },
  { name: 'thumbnail', maxCount: 1 },
  { name: 'subtitles', maxCount: 1 },
]), (req, res) => {
  try {
    const videoFile = req.files['video'] ? req.files['video'][0] : null;
    const thumbFile = req.files['thumbnail'] ? req.files['thumbnail'][0] : null;
    const subFile = req.files['subtitles'] ? req.files['subtitles'][0] : null;

    const episode = episodeStore.create({
      title: req.body.title,
      teaser: req.body.teaser,
      tier: req.body.tier,
      videoUrl: videoFile ? `/uploads/${videoFile.filename}` : req.body.videoUrl,
      thumbnailUrl: thumbFile ? `/uploads/${thumbFile.filename}` : (req.body.thumbnailUrl || ''),
      subtitleUrl: subFile ? `/uploads/${subFile.filename}` : (req.body.subtitleUrl || ''),
      durationSeconds: parseInt(req.body.durationSeconds, 10) || 0,
      emailSubject: req.body.emailSubject || req.body.title,
      publishDate: req.body.publishDate,
    });

    synapticRelay.logEvent('content', 'episode_uploaded', { episodeId: episode.id, tier: episode.tier });
    res.redirect('/admin');
  } catch (err) {
    res.status(400).send(`Upload failed: ${err.message}`);
  }
});

// Batch upload (multiple episodes via JSON)
router.post('/admin/batch-upload', requireAdmin, express.json(), (req, res) => {
  const results = [];
  for (const ep of req.body.episodes) {
    try {
      const episode = episodeStore.create(ep);
      results.push({ id: episode.id, title: episode.title, status: 'created' });
    } catch (err) {
      results.push({ title: ep.title, status: 'failed', error: err.message });
    }
  }
  synapticRelay.logEvent('content', 'batch_upload', { count: results.length });
  res.json({ results });
});

// QC pass
router.post('/admin/episodes/:id/qc', requireAdmin, express.json(), (req, res) => {
  const ep = episodeStore.markQCPassed(req.params.id);
  if (!ep) return res.status(404).json({ error: 'Episode not found' });
  synapticRelay.logEvent('content', 'qc_passed', { episodeId: ep.id });
  res.json({ episode: ep });
});

// Publish episode
router.post('/admin/episodes/:id/publish', requireAdmin, express.json(), (req, res) => {
  try {
    const ep = episodeStore.publish(req.params.id);
    if (!ep) return res.status(404).json({ error: 'Episode not found' });
    synapticRelay.logEvent('content', 'episode_published', { episodeId: ep.id });
    res.json({ episode: ep });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Acknowledge alert
router.post('/admin/alerts/:id/acknowledge', requireAdmin, express.json(), (req, res) => {
  const alert = synapticRelay.acknowledgeAlert(req.params.id);
  res.json({ alert });
});

// DLQ viewer
router.get('/admin/dlq', requireAdmin, (req, res) => {
  const items = deadLetterQueue.getAll();
  res.json(items);
});

// Retry DLQ item
router.post('/admin/dlq/:id/retry', requireAdmin, express.json(), (req, res) => {
  const item = deadLetterQueue.markRetrying(req.params.id);
  res.json({ item });
});

// --- Page builders ---

function buildAdminDashboard({ episodes, stats, mcBuffer, ncBuffer, health, dlqStats, alerts }) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Admin - AI Over Coffee</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="admin-page">
  <header class="admin-header">
    <h1>AI Over Coffee &mdash; Command Center</h1>
    <nav>
      <a href="/admin/calendar">Content Calendar</a>
      <a href="/admin/upload">Upload Episode</a>
      <a href="/admin/dlq">Dead Letter Queue</a>
      <a href="/logout">Sign Out</a>
    </nav>
  </header>
  <main class="admin-main">

    ${alerts.length > 0 ? `
    <section class="alerts-panel">
      <h2>Active Alerts</h2>
      ${alerts.map(a => `
        <div class="alert-card alert-${a.severity}">
          <strong>${a.metric}</strong>: ${a.message}
          <br><small>${a.timestamp}</small>
          <form method="POST" action="/admin/alerts/${a.id}/acknowledge" style="display:inline;">
            <button type="submit" class="btn-small">Acknowledge</button>
          </form>
        </div>`).join('')}
    </section>` : ''}

    <section class="stats-grid">
      <div class="stat-card">
        <span class="stat-number">${stats.totalActive}</span>
        <span class="stat-label">Active Members</span>
      </div>
      <div class="stat-card">
        <span class="stat-number">$${stats.mrr}</span>
        <span class="stat-label">MRR</span>
      </div>
      <div class="stat-card">
        <span class="stat-number">${stats.morningCoffee}</span>
        <span class="stat-label">Morning Coffee</span>
      </div>
      <div class="stat-card">
        <span class="stat-number">${stats.nightcap}</span>
        <span class="stat-label">Nightcap</span>
      </div>
      <div class="stat-card ${mcBuffer < 7 ? 'stat-danger' : ''}">
        <span class="stat-number">${mcBuffer}</span>
        <span class="stat-label">MC Buffer</span>
      </div>
      <div class="stat-card ${ncBuffer < 7 ? 'stat-danger' : ''}">
        <span class="stat-number">${ncBuffer}</span>
        <span class="stat-label">NC Buffer</span>
      </div>
    </section>

    <section class="health-panel">
      <h2>Synaptic Relay (24h)</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <span class="stat-number">${health.last24h.emailsSent}</span>
          <span class="stat-label">Emails Sent</span>
        </div>
        <div class="stat-card ${health.last24h.emailFailureRate > 0.05 ? 'stat-danger' : ''}">
          <span class="stat-number">${(health.last24h.emailFailureRate * 100).toFixed(1)}%</span>
          <span class="stat-label">Email Fail Rate</span>
        </div>
        <div class="stat-card">
          <span class="stat-number">${health.last24h.paymentsProcessed}</span>
          <span class="stat-label">Payments</span>
        </div>
        <div class="stat-card">
          <span class="stat-number">${dlqStats.pending}</span>
          <span class="stat-label">DLQ Pending</span>
        </div>
      </div>
    </section>

    <section class="episodes-panel">
      <h2>Recent Episodes</h2>
      <table class="episodes-table">
        <thead>
          <tr><th>Title</th><th>Tier</th><th>Date</th><th>QC</th><th>Published</th><th>Actions</th></tr>
        </thead>
        <tbody>
          ${episodes.slice(0, 20).map(ep => `
          <tr>
            <td>${ep.title}</td>
            <td>${ep.tier === 'morning_coffee' ? 'MC' : 'NC'}</td>
            <td>${ep.publishDate || '-'}</td>
            <td>${ep.qcPassed ? 'PASS' : 'PENDING'}</td>
            <td>${ep.published ? 'LIVE' : '-'}</td>
            <td>
              ${!ep.qcPassed ? `<form method="POST" action="/admin/episodes/${ep.id}/qc" style="display:inline;"><button class="btn-small">QC Pass</button></form>` : ''}
              ${ep.qcPassed && !ep.published ? `<form method="POST" action="/admin/episodes/${ep.id}/publish" style="display:inline;"><button class="btn-small">Publish</button></form>` : ''}
            </td>
          </tr>`).join('')}
        </tbody>
      </table>
    </section>
  </main>
</body>
</html>`;
}

function buildCalendarPage(calendar) {
  const dates = Object.keys(calendar).sort();
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Content Calendar - AI Over Coffee</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="admin-page">
  <header class="admin-header">
    <h1>Content Calendar</h1>
    <nav><a href="/admin">&larr; Dashboard</a> <a href="/admin/upload">Upload</a></nav>
  </header>
  <main class="admin-main">
    <div class="calendar-grid">
      ${dates.map(date => `
      <div class="calendar-day">
        <h3>${date}</h3>
        ${calendar[date].map(ep => `
          <div class="calendar-episode ${ep.published ? 'published' : ''} ${ep.qcPassed ? 'qc-passed' : 'qc-pending'}">
            <span class="tier-badge">${ep.tier === 'morning_coffee' ? 'MC' : 'NC'}</span>
            ${ep.title}
          </div>`).join('')}
      </div>`).join('')}
    </div>
  </main>
</body>
</html>`;
}

function buildUploadPage() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Upload Episode - AI Over Coffee</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="admin-page">
  <header class="admin-header">
    <h1>Upload Episode</h1>
    <nav><a href="/admin">&larr; Dashboard</a> <a href="/admin/calendar">Calendar</a></nav>
  </header>
  <main class="admin-main">
    <form method="POST" action="/admin/upload" enctype="multipart/form-data" class="upload-form">
      <div class="form-group">
        <label for="title">Episode Title</label>
        <input type="text" id="title" name="title" required>
      </div>
      <div class="form-group">
        <label for="teaser">Teaser (for email)</label>
        <textarea id="teaser" name="teaser" rows="2"></textarea>
      </div>
      <div class="form-group">
        <label for="tier">Tier</label>
        <select id="tier" name="tier" required>
          <option value="morning_coffee">Morning Coffee</option>
          <option value="nightcap">Nightcap</option>
        </select>
      </div>
      <div class="form-group">
        <label for="video">Video File (MP4, 1080p)</label>
        <input type="file" id="video" name="video" accept="video/mp4">
        <small>Or provide a URL below</small>
        <input type="text" name="videoUrl" placeholder="https://...">
      </div>
      <div class="form-group">
        <label for="thumbnail">Thumbnail</label>
        <input type="file" id="thumbnail" name="thumbnail" accept="image/*">
        <input type="text" name="thumbnailUrl" placeholder="https://...">
      </div>
      <div class="form-group">
        <label for="subtitles">Subtitles (VTT)</label>
        <input type="file" id="subtitles" name="subtitles" accept=".vtt">
        <input type="text" name="subtitleUrl" placeholder="https://...">
      </div>
      <div class="form-row">
        <div class="form-group">
          <label for="durationSeconds">Duration (seconds)</label>
          <input type="number" id="durationSeconds" name="durationSeconds" min="60" max="600">
        </div>
        <div class="form-group">
          <label for="publishDate">Publish Date</label>
          <input type="date" id="publishDate" name="publishDate" required>
        </div>
      </div>
      <div class="form-group">
        <label for="emailSubject">Email Subject Line</label>
        <input type="text" id="emailSubject" name="emailSubject">
      </div>
      <button type="submit" class="btn-primary">Upload Episode</button>
    </form>
  </main>
</body>
</html>`;
}

module.exports = router;
