
import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('Enhanced Transform Tests - Decoder', () {
    test('Transform by index', () {
      final input = 'a,b,c\n1,2,3';
      final decoder = CsvDecoder(
        fieldDelimiter: ',',
        fieldTransform: (value, index, header) {
          if (index == 1) return 'x-$value';
          return value;
        },
      );
      final result = decoder.convert(input);
      expect(result, equals([
        ['a', 'x-b', 'c'],
        ['1', 'x-2', '3']
      ]));
    });

    test('Transform by header name', () {
      final input = 'name,age\nAlice,30\nBob,25';
      final decoder = CsvDecoder(
        fieldDelimiter: ',',
        parseHeaders: true,
        fieldTransform: (value, index, header) {
          if (header == 'age') return int.parse(value);
          return value;
        },
      );
      final result = decoder.convert(input);
      expect((result[0] as CsvRow)['age'], equals(30));
      expect((result[1] as CsvRow)['age'], equals(25));
      expect((result[0] as CsvRow)['name'], equals('Alice'));
    });
  });

  group('Enhanced Transform Tests - Encoder', () {
    test('Transform by index', () {
      final input = [['a', 'b'], [1, 2]];
      final encoder = CsvEncoder(
        fieldTransform: (value, index, header) {
          if (index == 0) return 'col0-$value';
          return value;
        },
      );
      expect(encoder.convert(input), equals('col0-a,b\r\ncol0-1,2'));
    });

    test('Transform by header name (with CsvRow)', () {
      final headers = {'id': 0, 'val': 1};
      final input = [
        CsvRow(['1', 'a'], headers),
        CsvRow(['2', 'b'], headers),
      ];
      final encoder = CsvEncoder(
        fieldTransform: (value, index, header) {
          if (header == 'val') return value.toUpperCase();
          return value;
        },
      );
      expect(encoder.convert(input), equals('1,A\r\n2,B'));
    });
  });
}
