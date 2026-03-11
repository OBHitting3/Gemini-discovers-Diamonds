// Landing page builder

function buildLandingPage() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AI Over Coffee - AI education for business owners who built it themselves</title>
  <meta name="description" content="Daily AI education for solo business owners aged 55-75. Story-driven, jargon-free. It's not smarter than you. It's just faster.">
  <link rel="stylesheet" href="/css/style.css">
</head>
<body>
  <header class="landing-header">
    <h1>AI Over Coffee</h1>
    <a href="/login">Member Sign In</a>
  </header>

  <section class="hero">
    <h2>AI isn't smarter than you.<br>It's just faster.</h2>
    <p class="tagline">Daily AI education for the owner who built it themselves.</p>
    <p>
      You didn't get here by following trends. But AI is moving fast, and the owners
      who understand it first will have an edge that compounds. Three minutes a day.
      Stories, not lectures. Built for you.
    </p>
    <a href="#pricing" class="cta-btn">See the Plans</a>
  </section>

  <section class="about-section">
    <h2>Here's how it works</h2>
    <p>
      Every morning, a short episode lands in your inbox. It tells you one thing AI
      can do for a business like yours, wrapped in a story you'll actually remember.
      No jargon. No homework. Just the kind of thing you'd tell a friend about over coffee.
    </p>
    <p>
      You watch it on your phone, your laptop, wherever you are.
      Three to four minutes. Then you go run your business &mdash;
      knowing something your competitors don't.
    </p>
  </section>

  <section class="pricing-section" id="pricing">
    <h2>Choose your pace</h2>

    <div style="max-width:400px;margin:0 auto 32px;text-align:center;">
      <label for="checkout-email" style="display:block;font-size:17px;color:#4A3728;margin-bottom:8px;">
        Your email address
      </label>
      <input type="email" id="checkout-email" placeholder="karl@example.com"
        style="width:100%;padding:14px;border:1px solid #E8D5B7;border-radius:6px;font-size:17px;font-family:Georgia,serif;text-align:center;">
    </div>

    <div class="pricing-grid">
      <div class="pricing-card">
        <h3>Morning Coffee</h3>
        <div class="price">$25<span>/month</span></div>
        <ul class="features">
          <li>Daily 3&ndash;4 minute episode</li>
          <li>Delivered at 6:00 AM your time</li>
          <li>Story-driven, no jargon</li>
          <li>Full episode archive on your dashboard</li>
          <li>Watch on any device</li>
          <li>Cancel anytime</li>
        </ul>
        <button class="select-btn" onclick="startCheckout('morning_coffee')">
          Start Morning Coffee
        </button>
      </div>

      <div class="pricing-card featured">
        <h3>Nightcap</h3>
        <div class="price">$49<span>/month</span></div>
        <ul class="features">
          <li>Everything in Morning Coffee</li>
          <li>Plus daily 5&ndash;7 minute deep dive</li>
          <li>Evening delivery at 7:00 PM your time</li>
          <li>Deeper AI strategy for your business</li>
          <li>Full archive access</li>
          <li>Cancel anytime</li>
        </ul>
        <button class="select-btn" onclick="startCheckout('nightcap')">
          Start Nightcap
        </button>
      </div>
    </div>
  </section>

  <section class="about-section">
    <h2>Built for owners like you</h2>
    <p>
      State Farm agents. Realtors. Attorneys. Shop owners. Contractors.
      Trucking companies. If you built your business with your own hands
      and you're still the one running it &mdash; this is for you.
    </p>
    <p>
      We don't do tutorials. We don't do buzzwords.
      We tell you what's real, what works, and what's coming next &mdash;
      in plain English, with a story you'll remember.
    </p>
  </section>

  <footer class="footer">
    <p>&copy; ${new Date().getFullYear()} Iron Forge Studios. All rights reserved.</p>
    <p style="margin-top:8px;">AI Over Coffee is a product of Iron Forge Studios.</p>
  </footer>

  <script src="/js/checkout.js"></script>
</body>
</html>`;
}

module.exports = { buildLandingPage };
