/// URL pública do app do hóspede (`apps/konekto_mobile`, build web) — o
/// mesmo link serve pra todo mundo (o hóspede digita seu próprio código
/// depois de abrir); não é por-hóspede. Usado pra montar o QR code fixo
/// de recepção e a mensagem pronta de convite. Troque em tempo de build:
///
///   flutter run --dart-define=GUEST_APP_URL=http://localhost:port
const String guestAppUrl = String.fromEnvironment(
  'GUEST_APP_URL',
  defaultValue: 'https://konekto-guest.vercel.app',
);
