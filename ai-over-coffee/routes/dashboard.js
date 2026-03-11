// Member Dashboard Routes

const express = require('express');
const router = express.Router();
const { requireMember } = require('../middleware/auth');
const { memberStore } = require('../services/members');
const { episodeStore } = require('../services/episodes');
const { synapticRelay } = require('../services/synaptic-relay');

// Login page
router.get('/login', (req, res) => {
  res.send(buildLoginPage());
});

router.post('/login', express.urlencoded({ extended: true }), (req, res) => {
  const { email } = req.body;
  const member = memberStore.getByEmail(email);
  if (!member) {
    return res.send(buildLoginPage('No active membership found for that email.'));
  }
  req.session.memberId = member.id;
  synapticRelay.logEvent('auth', 'member_login', { email: member.email });
  res.redirect('/dashboard');
});

router.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/');
});

// Member dashboard
router.get('/dashboard', requireMember, (req, res) => {
  const member = memberStore.getById(req.session.memberId);
  if (!member) {
    req.session.destroy();
    return res.redirect('/login');
  }

  const morningCoffeeEpisodes = member.morningCoffeeAccess
    ? episodeStore.getPublishedForTier('morning_coffee') : [];
  const nightcapEpisodes = member.nightcapAccess
    ? episodeStore.getPublishedForTier('nightcap') : [];

  res.send(buildDashboard(member, morningCoffeeEpisodes, nightcapEpisodes));
});

// Watch episode page
router.get('/watch/:episodeId', requireMember, (req, res) => {
  const member = memberStore.getById(req.session.memberId);
  const episode = episodeStore.getById(req.params.episodeId);

  if (!episode) return res.status(404).send('Episode not found');

  // Tier check
  if (episode.tier === 'nightcap' && !member.nightcapAccess) {
    return res.status(403).send('Upgrade to Nightcap to access this episode.');
  }

  // Mark watched
  memberStore.markEpisodeWatched(member.id, episode.id);
  synapticRelay.logEvent('content', 'episode_watched', {
    memberId: member.id,
    episodeId: episode.id,
  });

  res.send(buildWatchPage(member, episode));
});

// --- Page builders ---

function buildLoginPage(error = '') {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign In - AI Over Coffee</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="login-page">
  <div class="login-container">
    <h1>AI Over Coffee</h1>
    <p class="tagline">Welcome back.</p>
    ${error ? `<p class="error">${error}</p>` : ''}
    <form method="POST" action="/login">
      <label for="email">Your email address</label>
      <input type="email" id="email" name="email" required placeholder="karl@example.com">
      <button type="submit">Sign In</button>
    </form>
    <p class="back-link"><a href="/">Back to home</a></p>
  </div>
</body>
</html>`;
}

function buildDashboard(member, mcEpisodes, ncEpisodes) {
  const greeting = getTimeGreeting();
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Dashboard - AI Over Coffee</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="dashboard-page">
  <header class="dash-header">
    <div class="dash-header-inner">
      <h1>AI Over Coffee</h1>
      <nav>
        <span class="member-name">${member.firstName}</span>
        <a href="/logout">Sign Out</a>
      </nav>
    </div>
  </header>
  <main class="dash-main">
    <h2>${greeting}, ${member.firstName}.</h2>

    ${mcEpisodes.length > 0 ? `
    <section class="episode-section">
      <h3>Morning Coffee</h3>
      <div class="episode-grid">
        ${mcEpisodes.map(ep => episodeCard(ep, member)).join('')}
      </div>
    </section>` : ''}

    ${ncEpisodes.length > 0 ? `
    <section class="episode-section">
      <h3>Nightcap</h3>
      <div class="episode-grid">
        ${ncEpisodes.map(ep => episodeCard(ep, member)).join('')}
      </div>
    </section>` : ''}

    ${mcEpisodes.length === 0 && ncEpisodes.length === 0 ? `
    <div class="empty-state">
      <p>Your first episodes are being prepared. Check back soon.</p>
    </div>` : ''}
  </main>
</body>
</html>`;
}

function episodeCard(episode, member) {
  const watched = member.watchedEpisodes.includes(episode.id);
  return `
    <a href="/watch/${episode.id}" class="episode-card ${watched ? 'watched' : 'unwatched'}">
      <div class="episode-thumb">
        ${episode.thumbnailUrl
          ? `<img src="${episode.thumbnailUrl}" alt="${episode.title}" loading="lazy">`
          : `<div class="thumb-placeholder"></div>`}
        ${watched ? '<span class="watched-badge">Watched</span>' : ''}
      </div>
      <h4>${episode.title}</h4>
      <span class="episode-duration">${formatDuration(episode.durationSeconds)}</span>
    </a>`;
}

function buildWatchPage(member, episode) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${episode.title} - AI Over Coffee</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="watch-page">
  <header class="dash-header">
    <div class="dash-header-inner">
      <a href="/dashboard" class="back-btn">&larr; Back to Dashboard</a>
      <h1>AI Over Coffee</h1>
    </div>
  </header>
  <main class="watch-main">
    <div class="video-container">
      <video controls autoplay width="100%" poster="${episode.thumbnailUrl}">
        <source src="${episode.videoUrl}" type="video/mp4">
        ${episode.subtitleUrl ? `<track kind="subtitles" src="${episode.subtitleUrl}" srclang="en" label="English" default>` : ''}
        Your browser does not support the video tag.
      </video>
      <div class="subtitle-toggle">
        <label>
          <input type="checkbox" id="subtitleToggle" checked onchange="toggleSubtitles(this)">
          Subtitles
        </label>
      </div>
    </div>
    <h2>${episode.title}</h2>
    <p class="episode-meta">${formatDuration(episode.durationSeconds)} &middot; ${episode.tier === 'morning_coffee' ? 'Morning Coffee' : 'Nightcap'}</p>
    ${episode.teaser ? `<p class="episode-teaser">${episode.teaser}</p>` : ''}
  </main>
  <script>
    function toggleSubtitles(checkbox) {
      const video = document.querySelector('video');
      if (video.textTracks.length > 0) {
        video.textTracks[0].mode = checkbox.checked ? 'showing' : 'hidden';
      }
    }
  </script>
</body>
</html>`;
}

function getTimeGreeting() {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

function formatDuration(seconds) {
  if (!seconds) return '';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${s.toString().padStart(2, '0')}`;
}

module.exports = router;
