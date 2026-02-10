import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('CsvEncoder', () {
    test('Simple row', () {
      expect(
        csv.encode([
          ['A', 'b', 'c'],
        ]),
        equals('A,b,c'),
      );
    });

    test('Multiple rows', () {
      expect(
        csv.encode([
          ['A', 'b', 'c'],
          ['d', 'E', 'f'],
        ]),
        equals('A,b,c\r\nd,E,f'),
      );
    });

    test('Quoted field with delimiter', () {
      expect(
        csv.encode([
          ['A', 'B,B', 'C'],
        ]),
        equals('A,"B,B",C'),
      );
    });

    test('Quoted field with line break', () {
      expect(
        csv.encode([
          ['A', 'B\nB', 'C'],
        ]),
        equals('A,"B\nB",C'),
      );
    });

    test('Quoted field with escaped quotes', () {
      expect(
        csv.encode([
          ['A', 'B"B', 'C'],
        ]),
        equals('A,"B""B",C'),
      );
    });

    test('Excel mode', () {
      final input = [
        ['Header1', 'Header2'],
        ['Value1', 'Value;2'],
      ];
      final encoded = excel.encode(input);
      expect(encoded, startsWith('\ufeff'));
      expect(encoded, contains('Header1;Header2'));
      expect(encoded, contains('Value1;"Value;2"'));
    });
  });

  group('CsvDecoder', () {
    test('Simple row', () {
      expect(
        csv.decode('A,b,c'),
        equals([
          ['A', 'b', 'c'],
        ]),
      );
    });

    test('Two rows', () {
      expect(
        csv.decode('A,b,c\nd,E,f'),
        equals([
          ['A', 'b', 'c'],
          ['d', 'E', 'f'],
        ]),
      );
    });

    test('Quoted field', () {
      expect(
        csv.decode('A,"B",C'),
        equals([
          ['A', 'B', 'C'],
        ]),
      );
    });

    test('Quoted field with delimiter', () {
      expect(
        csv.decode('A,"B,B",C'),
        equals([
          ['A', 'B,B', 'C'],
        ]),
      );
    });

    test('Quoted field with line break', () {
      // PapaParse handles \n inside quotes
      expect(
        csv.decode('A,"B\nB",C'),
        equals([
          ['A', 'B\nB', 'C'],
        ]),
      );
    });

    test('Quoted field with escaped quotes', () {
      expect(
        csv.decode('A,"B""B",C'),
        equals([
          ['A', 'B"B', 'C'],
        ]),
      );
    });

    test('Auto-detect delimiter', () {
      expect(
        csv.decode('A;B;C'),
        equals([
          ['A', 'B', 'C'],
        ]),
      );
      expect(
        csv.decode('A\tB\tC'),
        equals([
          ['A', 'B', 'C'],
        ]),
      );
    });

    test('BOM stripping', () {
      expect(
        csv.decode('\ufeffA,B,C'),
        equals([
          ['A', 'B', 'C'],
        ]),
      );
    });

    test('Empty fields', () {
      expect(
        csv.decode('a,b,,,c,d'),
        equals([
          ['a', 'b', '', '', 'c', 'd'],
        ]),
      );
    });

    test('Trailing newline', () {
      final result = csv.decode('A,B,C\n');
      expect(result.length, greaterThanOrEqualTo(1));
    });
  });

  group('PapaParse edge cases', () {
    test('Whitespace at edges of unquoted field', () {
      expect(
        csv.decode('a,	b ,c'),
        equals([
          ['a', '	b ', 'c'],
        ]),
      );
    });

    test('Quoted field with extra whitespace on edges', () {
      expect(
        csv.decode('A," B  ",C'),
        equals([
          ['A', ' B  ', 'C'],
        ]),
      );
    });

    test('Unquoted field with quotes at end of field', () {
      expect(
        csv.decode('A,B",C'),
        equals([
          ['A', 'B"', 'C'],
        ]),
      );
    });

    test('Quoted field with 5 quotes in a row and a delimiter', () {
      expect(
        csv.decode('"1","cnonce="""",nc=""""","2"'),
        equals([
          ['1', 'cnonce="",nc=""', '2'],
        ]),
      );
    });
  });

  group('Chunked Conversion', () {
    test('Chunked decoding: split row', () async {
      final input = Stream.fromIterable(['A,B,C\nd', ',e,f']);
      final result = await input.transform(CsvCodec(fieldDelimiter: ',').decoder).toList();
      expect(
        result,
        equals([
          [
            ['A', 'B', 'C'],
          ],
          [
            ['d', 'e', 'f'],
          ],
        ]),
      );
    });

    test('Chunked decoding: split quoted field', () async {
      final input = Stream.fromIterable(['A,"B\n', 'B",C']);
      final result = await input.transform(CsvCodec(fieldDelimiter: ',').decoder).toList();
      expect(
        result,
        equals([
          [
            ['A', 'B\nB', 'C'],
          ],
        ]),
      );
    });

    test('Chunked encoding', () async {
      final input = Stream.fromIterable(
        [
          [
            ['A', 'B'],
          ],
          [
            ['C', 'D'],
          ],
        ].cast<List<List<dynamic>>>(),
      );
      final result = await input.transform(csv.encoder).join();
      expect(result, equals('A,B\r\nC,D'));
    });
  });

  group('Advanced Features', () {
    test('QuoteMode.strings', () {
      final codec = CsvCodec(quoteMode: QuoteMode.strings);
      final input = [
        [1, "1", true, "true"],
      ];
      expect(codec.encode(input), equals('1,"1",true,"true"'));
    });

    test('QuoteMode.always', () {
      final codec = CsvCodec(quoteMode: QuoteMode.always);
      final input = [
        [1, "A"],
      ];
      expect(codec.encode(input), equals('"1","A"'));
    });

    test('sep=; header detection', () {
      final input = 'sep=;\r\nA;B;C';
      expect(
        csv.decode(input),
        equals([
          ['A', 'B', 'C'],
        ]),
      );
    });

    test('sep=; header detection - no auto-detection', () {
      final input = 'sep=;\r\nA,B,C';
      expect(
        csv.decode(input),
        equals([
          ['A,B,C'],
        ]),
      );
    });

    test('skipEmptyLines', () {
      final codec = CsvCodec(skipEmptyLines: true);
      final input = 'A,B\n\nC,D\n\n';
      expect(
        codec.decode(input),
        equals([
          ['A', 'B'],
          ['C', 'D'],
        ]),
      );

      final codecNoSkip = CsvCodec(skipEmptyLines: false);
      expect(codecNoSkip.decode(input).length, equals(4));
    });

    test('fieldTransform - decimal separator', () {
      final encoder = CsvEncoder(
        fieldDelimiter: ';',
        fieldTransform: (f, i, h) {
          if (f is double) return f.toString().replaceAll('.', ',');
          return f;
        },
      );
      expect(
        encoder.convert([
          [1.23],
        ]),
        equals('1,23'),
      );

      final decoder = CsvDecoder(
        fieldDelimiter: ';',
        fieldTransform: (f, i, h) {
          if (f.contains(',')) {
            return double.tryParse(f.replaceAll(',', '.')) ?? f;
          }
          return f;
        },
      );
      expect(
        decoder.convert('1,23'),
        equals([
          [1.23],
        ]),
      );
    });

    test('Custom escapeCharacter', () {
      final encoder = CsvEncoder(escapeCharacter: '\\');
      expect(
        encoder.convert([
          ['A"B'],
        ]),
        equals('"A\\"B"'),
      );
    });

    test('CsvRow and parseHeaders', () {
      final input = 'id,name\n1,Alice\n2,Bob';
      final codec = CsvCodec(parseHeaders: true);
      final result = codec.decode(input);

      expect(result.length, equals(2));
      final row1 = result[0] as dynamic;
      final row2 = result[1] as dynamic;

      expect(row1['id'], equals('1'));
      expect(row1['name'], equals('Alice'));
      expect(row2['id'], equals('2'));
      expect(row2['name'], equals('Bob'));

      // Also accessible by index
      expect(result[0][0], equals('1'));

      // Map representation
      expect(result[0] is CsvRow, isTrue);
      final map = (result[0] as CsvRow).toMap();
      expect(map, equals({'id': '1', 'name': 'Alice'}));
    });
  });
}
