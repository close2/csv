import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('Split CRLF', () {
    test('Split CRLF', () {
      final output = <List<dynamic>>[];
      final outSink = _CollectorSink(output);

      final decoderSink = CsvDecoder(fieldDelimiter: ',').startChunkedConversion(outSink);

      // Split 'a\r\nb' into 'a\r' and '\nb'
      decoderSink.add('a\r');
      decoderSink.add('\nb');
      decoderSink.close();

      expect(output, equals([['a'], ['b']]));
    });

    test('Split CRLF with skipEmptyLines: false', () {
      final output = <List<dynamic>>[];
      final outSink = _CollectorSink(output);

      final decoderSink = CsvDecoder(fieldDelimiter: ',', skipEmptyLines: false).startChunkedConversion(outSink);

      // Split 'a\r\nb' into 'a\r' and '\nb'
      decoderSink.add('a\r');
      decoderSink.add('\nb');
      decoderSink.close();

      expect(output, equals([['a'], ['b']]));
    });
  });
}

class _CollectorSink implements Sink<List<dynamic>> {
  final List<List<dynamic>> _target;
  _CollectorSink(this._target);

  @override
  void add(List<dynamic> data) => _target.add(data);

  @override
  void close() {}
}
