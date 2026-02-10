
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('Multi-character delimiter', () {
    test('Basic multi-char delimiter', () {
      final decoder = CsvDecoder(fieldDelimiter: '::');
      expect(decoder.convert('a::b::c'), equals([['a', 'b', 'c']]));
    });

    test('Split multi-char delimiter', () {
      final output = <List<dynamic>>[];
      final outSink = ChunkedConversionSink<List<List<dynamic>>>.withCallback((
        accumulated,
      ) {
        for (final rows in accumulated) {
          output.addAll(rows);
        }
      });

      // Delimiter is '::'
      final decoderSink = CsvDecoder(fieldDelimiter: '::')
          .startChunkedConversion(outSink);

      // Split 'a::b' into 'a:' and ':b'
      decoderSink.add('a:');
      decoderSink.add(':b');
      decoderSink.close();

      expect(output, equals([['a', 'b']]));
    });

    test('Split multi-char delimiter after quote', () {
       final output = <List<dynamic>>[];
      final outSink = ChunkedConversionSink<List<List<dynamic>>>.withCallback((
        accumulated,
      ) {
        for (final rows in accumulated) {
          output.addAll(rows);
        }
      });

      // Delimiter is '::'
      final decoderSink = CsvDecoder(fieldDelimiter: '::')
          .startChunkedConversion(outSink);

      // Input: "a"::b
      // Split: "a": and :b
      decoderSink.add('"a":');
      decoderSink.add(':b');
      decoderSink.close();

      expect(output, equals([['a', 'b']]));
    });
  });
}
