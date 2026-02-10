
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('Split CRLF', () {
    test('Split CRLF', () {
      final output = <List<dynamic>>[];
      final outSink = ChunkedConversionSink<List<List<dynamic>>>.withCallback((
        accumulated,
      ) {
        for (final rows in accumulated) {
          output.addAll(rows);
        }
      });

      final decoderSink = CsvDecoder(fieldDelimiter: ',').startChunkedConversion(outSink);

      // Split 'a\r\nb' into 'a\r' and '\nb'
      decoderSink.add('a\r');
      decoderSink.add('\nb');
      decoderSink.close();

      expect(output, equals([['a'], ['b']]));
    });

    test('Split CRLF with skipEmptyLines: false', () {
      final output = <List<dynamic>>[];
      final outSink = ChunkedConversionSink<List<List<dynamic>>>.withCallback((
        accumulated,
      ) {
        for (final rows in accumulated) {
          output.addAll(rows);
        }
      });

      final decoderSink = CsvDecoder(fieldDelimiter: ',', skipEmptyLines: false).startChunkedConversion(outSink);

      // Split 'a\r\nb' into 'a\r' and '\nb'
      decoderSink.add('a\r');
      decoderSink.add('\nb');
      decoderSink.close();

      expect(output, equals([['a'], ['b']]));
    });
  });
}
