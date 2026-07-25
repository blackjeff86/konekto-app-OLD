// JWT_SECRET precisa existir antes de qualquer import de lib/jwt.ts ou
// lib/guest-auth.ts (ambos lançam na primeira chamada se a env var faltar).
process.env.JWT_SECRET = 'test-secret-only-used-in-automated-tests'
// Secret separado do de staff/hóspede de propósito (ver lib/platform-auth.ts) —
// precisa existir antes de qualquer import desse módulo.
process.env.PLATFORM_ADMIN_JWT_SECRET = 'test-platform-admin-secret-only-used-in-automated-tests'
