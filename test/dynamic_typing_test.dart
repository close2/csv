
import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('Dynamic Typing Tests', () {
    test('Parse integers', () {
      final input = '123,-456';
      final decoder = CsvDecoder(dynamicTyping: true);
      final result = decoder.convert(input);
      expect(result[0][0], equals(123));
      expect(result[0][1], equals(-456));
      expect(result[0][0], isA<int>());
    });

    test('Parse doubles', () {
      final input = '1.23,1e10,.5';
      final decoder = CsvDecoder(dynamicTyping: true);
      final result = decoder.convert(input);
      expect(result[0][0], equals(1.23));
      expect(result[0][1], equals(1e10));
      expect(result[0][2], equals(0.5));
      expect(result[0][0], isA<double>());
    });

    test('Parse booleans', () {
      final input = 'true,false';
      final decoder = CsvDecoder(dynamicTyping: true);
      final result = decoder.convert(input);
      expect(result[0][0], isTrue);
      expect(result[0][1], isFalse);
    });

    test('Mixed data and types', () {
      final input = '123,true,hello,1.5';
      final decoder = CsvDecoder(dynamicTyping: true);
      final result = decoder.convert(input);
      expect(result[0], equals([123, true, 'hello', 1.5]));
    });

    test('Quoted values are also typed (PapaParse semantics)', () {
      final input = '"123","true","3.14"';
      final decoder = CsvDecoder(dynamicTyping: true);
      final result = decoder.convert(input);
      expect(result[0], equals([123, true, 3.14]));
    });

    test('Booleans must be exact match (PapaParse semantics)', () {
      final input = 'TRUE,False,true';
      final decoder = CsvDecoder(dynamicTyping: true);
      final result = decoder.convert(input);
      expect(result[0], equals(['TRUE', 'False', true]));
    });
  });
}
