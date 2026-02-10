
import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('CsvDecoder Validation', () {
    test('Invalid quoteCharacter', () {
      expect(() => CsvDecoder(quoteCharacter: 'xx'), throwsA(isA<AssertionError>()));
    });

    test('Invalid escapeCharacter', () {
      expect(() => CsvDecoder(escapeCharacter: 'xx'), throwsA(isA<AssertionError>()));
    });

    test('Valid parameters', () {
      expect(() => CsvDecoder(quoteCharacter: '"', escapeCharacter: '\\'), returnsNormally);
    });
  });
}
