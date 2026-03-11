// Stripe checkout handler for landing page

async function startCheckout(tierId) {
  const emailInput = document.getElementById('checkout-email');
  const email = emailInput ? emailInput.value : '';

  if (!email || !email.includes('@')) {
    alert('Please enter your email address above.');
    return;
  }

  const button = event.target;
  button.disabled = true;
  button.textContent = 'Redirecting...';

  try {
    const res = await fetch('/checkout/create-checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier: tierId, email }),
    });

    const data = await res.json();

    if (data.url) {
      window.location.href = data.url;
    } else {
      alert(data.error || 'Something went wrong. Please try again.');
      button.disabled = false;
      button.textContent = tierId === 'morning_coffee' ? 'Start Morning Coffee' : 'Start Nightcap';
    }
  } catch (err) {
    alert('Connection error. Please try again.');
    button.disabled = false;
    button.textContent = tierId === 'morning_coffee' ? 'Start Morning Coffee' : 'Start Nightcap';
  }
}
