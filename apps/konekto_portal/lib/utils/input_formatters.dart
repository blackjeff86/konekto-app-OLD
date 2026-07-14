import 'package:flutter/services.dart';

/// Remove tudo que não for dígito — usado antes de mandar um número
/// formatado (CPF, telefone) pra API, que sempre guarda só dígitos.
String stripNonDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

/// Formata progressivamente como `000.000.000-00` enquanto o usuário
/// digita. Só faz sentido pra `DocumentType.cpf` — passaporte/outro documento
/// não tem um formato fixo, então o campo fica livre nesses casos.
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = stripNonDigits(newValue.text);
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

/// Formata progressivamente como `(00) 00000-0000` (celular, 9º dígito) ou
/// `(00) 0000-0000` (fixo) enquanto o usuário digita — usado como
/// `inputFormatters` do campo de número dentro de `IntlPhoneField`. Precisa
/// vir acompanhado de `disableLengthCheck: true` nesse campo, senão o
/// `maxLength` interno do pacote (baseado em contagem de dígitos) corta o
/// texto antes de caber a máscara. O valor com máscara nunca é gravado
/// direto — sempre passa por [stripNonDigits] antes de ir pra API.
class BrazilPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = stripNonDigits(newValue.text);
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = format(limited);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }

  /// Também usado fora do formatter (ex: pra pré-preencher um
  /// `IntlPhoneField` a partir de um número já salvo sem máscara) — o
  /// `initialValue` de um campo não passa pelos `inputFormatters`.
  static String format(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer('(');
    final dddLength = digits.length < 2 ? digits.length : 2;
    buffer.write(digits.substring(0, dddLength));
    if (digits.length < 2) return buffer.toString();
    buffer.write(')');
    if (digits.length == 2) return buffer.toString();
    buffer.write(' ');

    final rest = digits.substring(2);
    final firstGroupLength = rest.length >= 9 ? 5 : 4;
    final firstLength = rest.length < firstGroupLength ? rest.length : firstGroupLength;
    buffer.write(rest.substring(0, firstLength));
    if (rest.length > firstLength) {
      buffer.write('-');
      buffer.write(rest.substring(firstLength));
    }
    return buffer.toString();
  }
}
