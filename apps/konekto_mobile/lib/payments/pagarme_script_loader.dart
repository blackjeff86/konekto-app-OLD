import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

const _scriptId = 'pagarme-tokenizecard-script';

/// Chave pública do Pagar.me (`pk_...`) — só ela, nunca a secreta, é
/// exposta no cliente (mesma lógica de uma chave publicável do Stripe).
/// Vem de `--dart-define=PAGARME_PUBLIC_KEY=...`, mesma convenção já usada
/// pra `API_BASE_URL`/`USE_API` neste projeto — nunca hardcoded, já que
/// muda entre ambiente de teste (`pk_test_...`) e produção (`pk_...`).
const String _pagarmePublicKey = String.fromEnvironment('PAGARME_PUBLIC_KEY');

/// Carrega o script de tokenização client-side do Pagar.me uma única vez
/// por sessão da página — idempotente (não recarrega se já presente no
/// DOM). O cartão nunca passa pelo nosso código Dart nem pelo backend, só
/// por esse script rodando no navegador.
Future<void> loadPagarmeScript() {
  if (_pagarmePublicKey.isEmpty) {
    return Future.error(StateError('PAGARME_PUBLIC_KEY não configurada neste build.'));
  }

  final existing = web.document.getElementById(_scriptId);
  if (existing != null) return Future.value();

  final completer = Completer<void>();
  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script.id = _scriptId;
  script.src = 'https://checkout.pagar.me/v1/tokenizecard.js';
  script.setAttribute('data-pagarmecheckout-app-id', _pagarmePublicKey);
  script.addEventListener(
    'load',
    ((web.Event _) {
      completer.complete();
    }).toJS,
  );
  script.addEventListener(
    'error',
    ((web.Event _) {
      completer.completeError(StateError('Falha ao carregar o script de pagamento.'));
    }).toJS,
  );
  web.document.head!.append(script);

  return completer.future;
}
