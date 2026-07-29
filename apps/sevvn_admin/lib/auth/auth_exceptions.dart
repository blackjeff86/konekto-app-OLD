/// Lançada quando o token guardado localmente não corresponde (mais) a um
/// admin válido na API — conta removida, token inválido/expirado, etc.
class AdminProfileNotFoundException implements Exception {
  const AdminProfileNotFoundException();
}

/// Lançada quando o login (e-mail/senha) é rejeitado pela API.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
}
