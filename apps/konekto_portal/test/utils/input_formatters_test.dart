import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konekto_portal/utils/input_formatters.dart';

TextEditingValue _value(String text) => TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

void main() {
  group('stripNonDigits', () {
    test('removes every non-digit character', () {
      expect(stripNonDigits('(21) 99462-2697'), '21994622697');
      expect(stripNonDigits('111.605.377-20'), '11160537720');
    });
  });

  group('CpfInputFormatter', () {
    final formatter = CpfInputFormatter();

    test('formats progressively as 000.000.000-00', () {
      expect(formatter.formatEditUpdate(_value(''), _value('1')).text, '1');
      expect(formatter.formatEditUpdate(_value(''), _value('111605377')).text, '111.605.377');
      expect(formatter.formatEditUpdate(_value(''), _value('11160537720')).text, '111.605.377-20');
    });

    test('ignores non-digit characters typed by the user', () {
      expect(formatter.formatEditUpdate(_value(''), _value('111.605.377-20')).text, '111.605.377-20');
    });

    test('caps at 11 digits', () {
      expect(formatter.formatEditUpdate(_value(''), _value('111605377209999')).text, '111.605.377-20');
    });
  });

  group('BrazilPhoneInputFormatter', () {
    final formatter = BrazilPhoneInputFormatter();

    test('formats a mobile number (11 digits) as (00) 00000-0000', () {
      expect(formatter.formatEditUpdate(_value(''), _value('21994622697')).text, '(21) 99462-2697');
    });

    test('formats a landline number (10 digits) as (00) 0000-0000', () {
      expect(formatter.formatEditUpdate(_value(''), _value('2133334444')).text, '(21) 3333-4444');
    });

    test('handles partial input while typing', () {
      expect(formatter.formatEditUpdate(_value(''), _value('2')).text, '(2');
      expect(formatter.formatEditUpdate(_value(''), _value('21')).text, '(21)');
      expect(formatter.formatEditUpdate(_value(''), _value('219')).text, '(21) 9');
    });

    test('format() static helper matches the live-typing formatter', () {
      expect(BrazilPhoneInputFormatter.format('21994622697'), '(21) 99462-2697');
    });
  });
}
