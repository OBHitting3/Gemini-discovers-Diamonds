const TIERS = {
  morning_coffee: {
    id: 'morning_coffee',
    name: 'Morning Coffee',
    price: 2500, // cents
    displayPrice: '$25',
    frequency: 'month',
    emailTime: '06:00',
    episodeDuration: '3-4 minutes',
    description: 'Daily 3-4 minute AI episodes delivered at 6:00 AM your time.',
    stripePriceId: process.env.STRIPE_MORNING_COFFEE_PRICE_ID || '',
    brevoListId: parseInt(process.env.BREVO_MORNING_COFFEE_LIST_ID || '1', 10),
  },
  nightcap: {
    id: 'nightcap',
    name: 'Nightcap',
    price: 4900,
    displayPrice: '$49',
    frequency: 'month',
    emailTime: '19:00',
    episodeDuration: '5-7 minutes',
    description: 'Everything in Morning Coffee plus daily 5-7 minute deep dives at 7:00 PM.',
    includesMorningCoffee: true,
    stripePriceId: process.env.STRIPE_NIGHTCAP_PRICE_ID || '',
    brevoListId: parseInt(process.env.BREVO_NIGHTCAP_LIST_ID || '2', 10),
  },
};

module.exports = { TIERS };
