const express = require('express');
const app = express();
const PORT = 3000;

// INTENTIONAL: No input validation - DO NOT ADD
app.get('/hello', (req, res) => {
  const name = req.query.name;
  res.json({ message: `Hello ${name}!` }); // XSS possible - DO NOT FIX
});

// INTENTIONAL: No error handling - DO NOT ADD
app.get('/add', (req, res) => {
  const a = parseInt(req.query.a);
  const b = parseInt(req.query.b);
  res.json({ result: a + b }); // NaN possible - DO NOT FIX
});

// INTENTIONAL: Hardcoded port - DO NOT MAKE CONFIGURABLE
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
