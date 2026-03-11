// Brevo (SendinBlue) Email Service
// Handles daily episode delivery, welcome emails, local-time scheduling

const https = require('https');
const { synapticRelay } = require('./synaptic-relay');
const { deadLetterQueue } = require('./dead-letter-queue');
const { assertions } = require('../config/assertions');

const BREVO_API_URL = 'api.brevo.com';

function brevoRequest(method, path, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: BREVO_API_URL,
      path,
      method,
      headers: {
        'api-key': process.env.BREVO_API_KEY,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    };

    const req = https.request(options, (res) => {
      let responseBody = '';
      res.on('data', chunk => { responseBody += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(responseBody ? JSON.parse(responseBody) : {});
        } else {
          reject(new Error(`Brevo API ${res.statusCode}: ${responseBody}`));
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

// Retry wrapper per OODA retry playbook
async function withRetry(fn, label, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxRetries) {
        deadLetterQueue.enqueue('email_delivery', { label, attempt }, err);
        synapticRelay.logEvent('email', 'delivery_failed', { label, error: err.message });
        throw err;
      }
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise(r => setTimeout(r, delay));
    }
  }
}

const brevo = {
  // Add subscriber to appropriate list on signup
  async addContact(email, firstName, tier) {
    const listIds = [tier.brevoListId];
    // Nightcap includes Morning Coffee
    if (tier.includesMorningCoffee) {
      const mcListId = parseInt(process.env.BREVO_MORNING_COFFEE_LIST_ID || '1', 10);
      listIds.push(mcListId);
    }

    return withRetry(() => brevoRequest('POST', '/v3/contacts', {
      email,
      attributes: { FIRSTNAME: firstName },
      listIds,
      updateEnabled: true,
    }), `add_contact_${email}`);
  },

  // Send welcome email with first 5 episodes
  async sendWelcomeEmail(email, firstName, tier) {
    return withRetry(() => brevoRequest('POST', '/v3/smtp/email', {
      sender: {
        email: process.env.BREVO_SENDER_EMAIL,
        name: process.env.BREVO_SENDER_NAME,
      },
      to: [{ email, name: firstName }],
      subject: `Welcome to AI Over Coffee, ${firstName}`,
      htmlContent: buildWelcomeHtml(firstName, tier),
    }), `welcome_email_${email}`);
  },

  // Send daily episode email
  async sendEpisodeEmail(email, firstName, episode) {
    assertions.emailContentValid({
      thumbnailUrl: episode.thumbnailUrl,
      episodeLink: episode.dashboardLink,
    });

    return withRetry(() => brevoRequest('POST', '/v3/smtp/email', {
      sender: {
        email: process.env.BREVO_SENDER_EMAIL,
        name: process.env.BREVO_SENDER_NAME,
      },
      to: [{ email, name: firstName }],
      subject: episode.emailSubject,
      htmlContent: buildEpisodeHtml(firstName, episode),
    }), `episode_email_${email}_${episode.id}`);
  },

  // Remove contact on cancellation
  async removeContact(email) {
    return withRetry(
      () => brevoRequest('DELETE', `/v3/contacts/${encodeURIComponent(email)}`),
      `remove_contact_${email}`
    );
  },
};

function buildWelcomeHtml(firstName, tier) {
  return `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#FFF8F0;font-family:Georgia,serif;">
  <div style="max-width:600px;margin:0 auto;padding:40px 20px;">
    <h1 style="color:#2C1810;font-size:28px;margin-bottom:8px;">Welcome to AI Over Coffee</h1>
    <p style="color:#8B6914;font-size:16px;margin-bottom:32px;font-style:italic;">
      "It's not smarter than you. It's just faster."
    </p>
    <p style="color:#4A3728;font-size:18px;line-height:1.6;">
      ${firstName}, you're in.
    </p>
    <p style="color:#4A3728;font-size:18px;line-height:1.6;">
      Your first five episodes are waiting on your dashboard right now.
      Starting tomorrow, you'll get a fresh one every ${tier.id === 'morning_coffee' ? 'morning at 6:00 AM' : 'morning and evening'}.
    </p>
    <div style="text-align:center;margin:40px 0;">
      <a href="${process.env.BASE_URL}/dashboard"
         style="background:#C8963E;color:#fff;text-decoration:none;padding:16px 40px;border-radius:6px;font-size:18px;display:inline-block;">
        Go to Your Dashboard
      </a>
    </div>
    <p style="color:#8B7355;font-size:14px;">
      Questions? Just reply to this email. We read every one.
    </p>
  </div>
</body>
</html>`;
}

function buildEpisodeHtml(firstName, episode) {
  return `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#FFF8F0;font-family:Georgia,serif;">
  <div style="max-width:600px;margin:0 auto;padding:40px 20px;">
    <p style="color:#8B6914;font-size:14px;margin-bottom:4px;">AI Over Coffee</p>
    <h1 style="color:#2C1810;font-size:24px;margin-bottom:24px;">${episode.title}</h1>
    <a href="${episode.dashboardLink}" style="display:block;text-decoration:none;">
      <img src="${episode.thumbnailUrl}" alt="${episode.title}"
           style="width:100%;border-radius:8px;border:1px solid #E8D5B7;" />
    </a>
    <p style="color:#4A3728;font-size:18px;line-height:1.6;margin-top:24px;">
      ${firstName}, ${episode.teaser}
    </p>
    <div style="text-align:center;margin:32px 0;">
      <a href="${episode.dashboardLink}"
         style="background:#C8963E;color:#fff;text-decoration:none;padding:14px 36px;border-radius:6px;font-size:17px;display:inline-block;">
        Watch Now
      </a>
    </div>
    <p style="color:#8B7355;font-size:13px;text-align:center;">
      ${episode.duration} &middot; Best with coffee
    </p>
  </div>
</body>
</html>`;
}

module.exports = { brevo };
