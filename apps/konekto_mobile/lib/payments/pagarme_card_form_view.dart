import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Formulário real de cartão — HTML puro, não widgets Flutter. Precisa ser
/// DOM de verdade porque o script `tokenizecard.js` do Pagar.me se liga a
/// atributos `data-pagarmecheckout-*` de elementos `<input>`/`<form>`
/// reais; Flutter web renderiza tudo via CanvasKit (não há DOM real por
/// trás de um `TextField`), então a única forma de embutir isso é via
/// `HtmlElementView` — o mesmo mecanismo usado pra mapas/iframes em apps
/// Flutter web. Estilizado via CSS inline pra ficar o mais parecido
/// possível com o resto do app, mas por ser HTML puro não fica
/// pixel-perfeito idêntico aos campos Flutter da tela.
class PagarmeCardFormView extends StatefulWidget {
  final String formElementId;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final String fontFamily;

  const PagarmeCardFormView({
    super.key,
    required this.formElementId,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.fontFamily,
  });

  @override
  State<PagarmeCardFormView> createState() => _PagarmeCardFormViewState();
}

class _PagarmeCardFormViewState extends State<PagarmeCardFormView> {
  static final Set<String> _registeredViewTypes = {};

  late final String _viewType = 'pagarme-card-form-${widget.formElementId}';

  @override
  void initState() {
    super.initState();
    if (_registeredViewTypes.add(_viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _buildFormElement());
    }
  }

  static String _colorToCss(Color color) => 'rgba(${color.r * 255}, ${color.g * 255}, ${color.b * 255}, ${color.a})';

  web.HTMLFormElement _buildFormElement() {
    final form = web.document.createElement('form') as web.HTMLFormElement;
    form.id = widget.formElementId;
    form.setAttribute('data-pagarmecheckout-form', '');
    form.style
      ..display = 'flex'
      ..flexDirection = 'column'
      ..gap = '10px'
      ..fontFamily = widget.fontFamily
      ..width = '100%'
      ..boxSizing = 'border-box';

    form.append(_buildField(label: 'Nome no cartão', element: 'holder_name'));
    form.append(_buildField(label: 'Número do cartão', element: 'number', inputMode: 'numeric'));

    final row = web.document.createElement('div') as web.HTMLDivElement;
    row.style
      ..display = 'flex'
      ..gap = '10px';
    row.append(_buildField(label: 'Mês (MM)', element: 'exp_month', inputMode: 'numeric', flex: '1'));
    row.append(_buildField(label: 'Ano (AA)', element: 'exp_year', inputMode: 'numeric', flex: '1'));
    row.append(_buildField(label: 'CVV', element: 'cvv', inputMode: 'numeric', flex: '1'));
    form.append(row);

    return form;
  }

  web.HTMLDivElement _buildField({required String label, required String element, String? inputMode, String? flex}) {
    final wrapper = web.document.createElement('div') as web.HTMLDivElement;
    if (flex != null) wrapper.style.flex = flex;

    final labelElement = web.document.createElement('label') as web.HTMLLabelElement;
    labelElement.textContent = label;
    labelElement.style
      ..display = 'block'
      ..fontSize = '11px'
      ..marginBottom = '4px'
      ..color = _colorToCss(widget.mutedColor);
    wrapper.append(labelElement);

    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'text';
    if (inputMode != null) input.setAttribute('inputmode', inputMode);
    input.setAttribute('data-pagarmecheckout-element', element);
    input.autocomplete = 'off';
    input.style
      ..width = '100%'
      ..boxSizing = 'border-box'
      ..padding = '12px'
      ..borderRadius = '10px'
      ..border = '1px solid ${_colorToCss(widget.mutedColor)}'
      ..fontSize = '14px'
      ..color = _colorToCss(widget.textColor)
      ..fontFamily = widget.fontFamily
      ..outline = 'none';
    wrapper.append(input);

    return wrapper;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 190, child: HtmlElementView(viewType: _viewType));
  }
}
