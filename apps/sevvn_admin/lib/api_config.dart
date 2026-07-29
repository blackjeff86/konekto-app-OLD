/// URL base do backend (apps/sevvn_api). Troque em tempo de build com:
///
///   flutter run --dart-define=API_BASE_URL=https://sua-api.vercel.app
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://sevvn-api.vercel.app',
);

