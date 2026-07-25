import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('PagarmeCheckout.init')
external void _pagarmeCheckoutInit(JSFunction onSuccess, JSFunction onFail);

/// Ponte JS interop pro script `tokenizecard.js` do Pagar.me — ele
/// tokeniza o cartão inteiramente no navegador (o dado bruto nunca chega
/// ao código Dart nem ao nosso backend, só o token resultante). O script
/// se liga a um `<form>` real do DOM via atributos
/// `data-pagarmecheckout-*` (não é uma função simples que devolve uma
/// Promise) — por isso o formulário de cartão precisa ser HTML real
/// embutido via `HtmlElementView` (ver `pagarme_card_form_view.dart`), não
/// `TextField`s do Flutter, que não existem como elementos DOM de
/// verdade.
///
/// NOTA: o formato exato da resposta do callback de sucesso (nome da
/// chave do token dentro do objeto devolvido) não foi confirmado 100% na
/// documentação consultada durante o planejamento desta feature — `_extractToken`
/// tenta os nomes mais prováveis e loga o payload bruto em caso de falha,
/// pra facilitar o ajuste na primeira tentativa real contra o sandbox do
/// Pagar.me antes de ir pra produção.
class PagarmeTokenizer {
  PagarmeTokenizer._();
  static final PagarmeTokenizer instance = PagarmeTokenizer._();

  Completer<String>? _pending;
  bool _initialized = false;

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _pagarmeCheckoutInit(
      ((JSAny data) {
        final pending = _pending;
        _pending = null;
        final token = _extractToken(data);
        if (pending != null && !pending.isCompleted) {
          if (token != null) {
            pending.complete(token);
          } else {
            web.console.warn('Pagar.me tokenization payload sem token reconhecido: $data'.toJS);
            pending.completeError(StateError('Não foi possível obter o token do cartão.'));
          }
        }
        return false.toJS;
      }).toJS,
      ((JSAny error) {
        final pending = _pending;
        _pending = null;
        if (pending != null && !pending.isCompleted) {
          pending.completeError(StateError('Não foi possível processar o cartão. Confira os dados e tente de novo.'));
        }
        return false.toJS;
      }).toJS,
    );
  }

  String? _extractToken(JSAny data) {
    final dartData = data.dartify();
    if (dartData is Map) {
      final token = dartData['pagarmetoken'] ?? dartData['token'];
      if (token is String && token.isNotEmpty) return token;
    }
    return null;
  }

  /// Dispara o submit do formulário real (elemento com `id` ==
  /// [formElementId]) e espera o token vir pelo callback de sucesso do
  /// `PagarmeCheckout.init`. Lança [StateError] em caso de falha, campo
  /// inválido, ou timeout.
  Future<String> tokenize(String formElementId) {
    _ensureInitialized();
    if (_pending != null && !_pending!.isCompleted) {
      throw StateError('Já existe uma tokenização em andamento.');
    }

    final formElement = web.document.getElementById(formElementId);
    if (formElement == null) {
      throw StateError('Formulário de cartão não encontrado.');
    }

    final completer = Completer<String>();
    _pending = completer;
    (formElement as web.HTMLFormElement).requestSubmit();

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _pending = null;
        throw StateError('Tempo esgotado ao processar o cartão.');
      },
    );
  }
}
