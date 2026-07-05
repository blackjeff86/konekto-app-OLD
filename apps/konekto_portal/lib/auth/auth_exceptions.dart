/// Lançada quando o token guardado localmente não corresponde (mais) a um
/// staff válido na API — conta removida, token inválido/expirado, etc.
class StaffProfileNotFoundException implements Exception {
  const StaffProfileNotFoundException();
}
