// Simple session-based auth middleware

function requireMember(req, res, next) {
  if (!req.session || !req.session.memberId) {
    return res.redirect('/login');
  }
  next();
}

function requireAdmin(req, res, next) {
  if (!req.session || !req.session.isAdmin) {
    return res.status(403).send('Forbidden');
  }
  next();
}

module.exports = { requireMember, requireAdmin };
