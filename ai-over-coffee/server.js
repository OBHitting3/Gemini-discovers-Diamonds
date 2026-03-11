// AI Over Coffee - Membership Platform Server
// Iron Forge Studios

require('dotenv').config();
const express = require('express');
const session = require('express-session');
const path = require('path');

const { buildLandingPage } = require('./views/landing');
const checkoutRoutes = require('./routes/checkout');
const dashboardRoutes = require('./routes/dashboard');
const adminRoutes = require('./routes/admin');
const { synapticRelay } = require('./services/synaptic-relay');

const app = express();
const PORT = process.env.PORT || 3000;

// Session
app.use(session({
  secret: process.env.SESSION_SECRET || 'dev-secret-change-me',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 30 * 24 * 60 * 60 * 1000 }, // 30 days
}));

// Static files
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Landing page
app.get('/', (req, res) => {
  res.send(buildLandingPage());
});

// Welcome page (post-checkout redirect)
app.get('/welcome', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Welcome - AI Over Coffee</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="login-page">
  <div class="login-container">
    <h1>You're in.</h1>
    <p class="tagline">Welcome to AI Over Coffee.</p>
    <p style="margin:20px 0;color:#4A3728;font-size:17px;">
      Check your inbox for your welcome email with your first five episodes.
      Your dashboard is ready.
    </p>
    <a href="/login" class="cta-btn" style="display:block;text-align:center;background:#C8963E;color:#fff;padding:14px;border-radius:6px;text-decoration:none;font-size:18px;">
      Go to Dashboard
    </a>
  </div>
</body>
</html>`);
});

// Routes
app.use('/checkout', checkoutRoutes);
app.use('/', dashboardRoutes);
app.use('/', adminRoutes);

// Health check
app.get('/health', (req, res) => {
  const dashboard = synapticRelay.getDashboard();
  res.json({ status: 'ok', ...dashboard });
});

// Start
app.listen(PORT, () => {
  synapticRelay.logEvent('system', 'server_started', { port: PORT });
  console.log(`AI Over Coffee running on port ${PORT}`);
  console.log(`Landing:   http://localhost:${PORT}`);
  console.log(`Dashboard: http://localhost:${PORT}/dashboard`);
  console.log(`Admin:     http://localhost:${PORT}/admin/login`);
});
