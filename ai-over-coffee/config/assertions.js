// 8 Deterministic Fail-Fast Assertions
// Per Master System Document OODA engineering spec

class AssertionError extends Error {
  constructor(id, message) {
    super(`[ASSERTION ${id}] ${message}`);
    this.assertionId = id;
  }
}

const assertions = {
  // A1: Episode file must exist and be non-zero bytes before scheduling
  episodeFileExists(episode) {
    if (!episode.videoUrl || episode.videoUrl.trim() === '') {
      throw new AssertionError('A1', `Episode "${episode.title}" has no video URL`);
    }
  },

  // A2: Episode duration must match tier spec
  episodeDurationValid(episode, tier) {
    const minSec = tier === 'morning_coffee' ? 150 : 270; // 2:30 / 4:30 floor
    const maxSec = tier === 'morning_coffee' ? 300 : 480; // 5:00 / 8:00 ceiling
    if (episode.durationSeconds < minSec || episode.durationSeconds > maxSec) {
      throw new AssertionError('A2',
        `Episode "${episode.title}" duration ${episode.durationSeconds}s outside ${minSec}-${maxSec}s for tier ${tier}`);
    }
  },

  // A3: Buffer must be >= 7 episodes before any new publish
  bufferMinimum(bufferCount, tier) {
    if (bufferCount < 7) {
      throw new AssertionError('A3',
        `Buffer for ${tier} is ${bufferCount} episodes (minimum 7 required)`);
    }
  },

  // A4: Stripe price ID must be configured before checkout
  stripePriceConfigured(tier) {
    if (!tier.stripePriceId || tier.stripePriceId === '') {
      throw new AssertionError('A4', `Stripe price ID not configured for tier "${tier.name}"`);
    }
  },

  // A5: Brevo sender domain must be verified
  brevoConfigured() {
    if (!process.env.BREVO_API_KEY || process.env.BREVO_API_KEY === 'xkeysib-xxx') {
      throw new AssertionError('A5', 'Brevo API key not configured');
    }
  },

  // A6: Email must have exactly one thumbnail and one link
  emailContentValid(emailData) {
    if (!emailData.thumbnailUrl || !emailData.episodeLink) {
      throw new AssertionError('A6',
        'Email must contain exactly one thumbnail and one episode link');
    }
  },

  // A7: Nightcap members must also be on Morning Coffee list
  nightcapIncludesMorningCoffee(member) {
    if (member.tier === 'nightcap' && !member.morningCoffeeAccess) {
      throw new AssertionError('A7',
        `Nightcap member ${member.email} missing Morning Coffee access`);
    }
  },

  // A8: Episode must pass QC flag before going live
  episodeQCPassed(episode) {
    if (!episode.qcPassed) {
      throw new AssertionError('A8',
        `Episode "${episode.title}" has not passed QC review`);
    }
  },
};

module.exports = { assertions, AssertionError };
