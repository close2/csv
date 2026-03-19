import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('asCodec()', () {
    late Csv csv;
    late Codec<List<List<dynamic>>, String> codec;

    setUp(() {
      csv = Csv();
      codec = csv.asCodec();
    });

    group('decoder', () {
      test('convert() decodes CSV string to rows', () {
        final result = codec.decoder.convert('a,b,c\r\n1,2,3');
        expect(result, [
          ['a', 'b', 'c'],
          ['1', '2', '3'],
        ]);
      });

      test('convert() handles empty input', () {
        final result = codec.decoder.convert('');
        expect(result, isEmpty);
      });

      test('convert() handles quoted fields', () {
        final result = codec.decoder.convert('"a,b",c\r\n"d""e",f');
        expect(result, [
          ['a,b', 'c'],
          ['d"e', 'f'],
        ]);
      });

      test('single chunk with multiple rows emits one batch', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final inputSink = codec.decoder.startChunkedConversion(outputSink);
        inputSink.add('a,b\r\n1,2\r\n3,4\r\n');
        inputSink.close();

        // All rows from one chunk should be in one batch.
        expect(batches.length, 1);
        expect(batches[0], [
          ['a', 'b'],
          ['1', '2'],
          ['3', '4'],
        ]);
      });

      test('separate chunks produce separate batches', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        // Use a preset delimiter to avoid auto-detection buffering.
        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec();
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);
        inputSink.add('a,b\r\n');
        inputSink.add('c,d\r\n');
        inputSink.close();

        // Each chunk should produce its own batch.
        expect(batches.length, 2);
        expect(batches[0], [['a', 'b']]);
        expect(batches[1], [['c', 'd']]);
      });

      test('10 rows in one chunk produce one batch of 10', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec();
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);

        final rows =
            '${List.generate(10, (i) => '$i,row$i').join('\r\n')}\r\n';
        inputSink.add(rows);
        inputSink.close();

        expect(batches.length, 1);
        expect(batches[0].length, 10);
        expect(batches[0][0], ['0', 'row0']);
        expect(batches[0][9], ['9', 'row9']);
      });
    });

    group('encoder', () {
      test('convert() encodes rows to CSV string', () {
        final result = codec.encoder.convert([
          ['a', 'b', 'c'],
          ['1', '2', '3'],
        ]);
        expect(result, 'a,b,c\r\n1,2,3');
      });

      test('convert() handles empty input', () {
        final result = codec.encoder.convert([]);
        expect(result, '');
      });

      test('convert() quotes fields that need quoting', () {
        final result = codec.encoder.convert([
          ['a,b', 'c"d'],
        ]);
        expect(result, '"a,b","c""d"');
      });
    });

    group('round-trip', () {
      test('encode then decode preserves data', () {
        final original = [
          ['name', 'age', 'city'],
          ['Alice', '30', 'New York'],
          ['Bob', '25', 'London'],
        ];
        final encoded = codec.encoder.convert(original);
        final decoded = codec.decoder.convert(encoded);
        expect(decoded, original);
      });
    });

    group('fuse', () {
      test('decoder can be fused with another converter', () {
        // Fuse with a converter that counts rows.
        final fused = codec.decoder.fuse(_RowCounter());
        final count = fused.convert('a,b\r\nc,d\r\ne,f');
        expect(count, 3);
      });
    });

    group('chunk boundary edge cases', () {
      test('split \\r\\n across chunks', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec();
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);

        // \r\n split: first chunk ends with \r, second starts with \n
        inputSink.add('a,b\r');
        inputSink.add('\nc,d\r\n');
        inputSink.close();

        final allRows = batches.expand((b) => b).toList();
        expect(allRows, [
          ['a', 'b'],
          ['c', 'd'],
        ]);
      });

      test('split escaped quote "" across chunks', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec();
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);

        // The "" escape is split: first chunk has the first ", second has "
        inputSink.add('a,"b"');
        inputSink.add('"c",d\r\n');
        inputSink.close();

        final allRows = batches.expand((b) => b).toList();
        expect(allRows, [
          ['a', 'b"c', 'd'],
        ]);
      });

      test('split in the middle of a field', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec();
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);

        inputSink.add('hel');
        inputSink.add('lo,wor');
        inputSink.add('ld\r\n');
        inputSink.close();

        final allRows = batches.expand((b) => b).toList();
        expect(allRows, [
          ['hello', 'world'],
        ]);
      });

      test('split inside a quoted field containing newline', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec();
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);

        // The quoted field "line1\nline2" is split across chunks
        inputSink.add('a,"line1\n');
        inputSink.add('line2",b\r\n');
        inputSink.close();

        final allRows = batches.expand((b) => b).toList();
        expect(allRows, [
          ['a', 'line1\nline2', 'b'],
        ]);
      });

      test('split at comma delimiter', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec();
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);

        inputSink.add('a,b');
        inputSink.add(',c\r\n');
        inputSink.close();

        final allRows = batches.expand((b) => b).toList();
        expect(allRows, [
          ['a', 'b', 'c'],
        ]);
      });

      test('single-character chunks through codec', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec();
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);

        // Feed one character at a time
        const input = 'a,b\r\nc,d\r\n';
        for (final ch in input.split('')) {
          inputSink.add(ch);
        }
        inputSink.close();

        final allRows = batches.expand((b) => b).toList();
        expect(allRows, [
          ['a', 'b'],
          ['c', 'd'],
        ]);
      });

      test('split escaped quote at every position via codec', () {
        const input = 'a,"b""c",d\r\n';
        final expected = [
          ['a', 'b"c', 'd'],
        ];

        for (int i = 0; i <= input.length; i++) {
          final chunk1 = input.substring(0, i);
          final chunk2 = input.substring(i);

          final batches = <List<List<dynamic>>>[];
          final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

          final csvFixed = Csv(autoDetect: false);
          final codecFixed = csvFixed.asCodec();
          final inputSink =
              codecFixed.decoder.startChunkedConversion(outputSink);

          if (chunk1.isNotEmpty) inputSink.add(chunk1);
          if (chunk2.isNotEmpty) inputSink.add(chunk2);
          inputSink.close();

          final allRows = batches.expand((b) => b).toList();
          expect(
            allRows,
            expected,
            reason: 'Failed when split at index $i.\n'
                'Chunk 1: "$chunk1"\n'
                'Chunk 2: "$chunk2"',
          );
        }
      });

      test('split \\r\\n at every position via codec', () {
        const input = 'x,y\r\na,b\r\n';
        final expected = [
          ['x', 'y'],
          ['a', 'b'],
        ];

        for (int i = 0; i <= input.length; i++) {
          final chunk1 = input.substring(0, i);
          final chunk2 = input.substring(i);

          final batches = <List<List<dynamic>>>[];
          final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

          final csvFixed = Csv(autoDetect: false);
          final codecFixed = csvFixed.asCodec();
          final inputSink =
              codecFixed.decoder.startChunkedConversion(outputSink);

          if (chunk1.isNotEmpty) inputSink.add(chunk1);
          if (chunk2.isNotEmpty) inputSink.add(chunk2);
          inputSink.close();

          final allRows = batches.expand((b) => b).toList();
          expect(
            allRows,
            expected,
            reason: 'Failed when split at index $i.\n'
                'Chunk 1: "$chunk1"\n'
                'Chunk 2: "$chunk2"',
          );
        }
      });

      test('maxRowsPerBatch with split \\r\\n', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecFixed = csvFixed.asCodec(maxRowsPerBatch: 1);
        final inputSink =
            codecFixed.decoder.startChunkedConversion(outputSink);

        // Split \r\n across chunks, with maxRowsPerBatch=1
        inputSink.add('a,b\r');
        inputSink.add('\nc,d\r\ne,f\r\n');
        inputSink.close();

        expect(batches.length, 3);
        final allRows = batches.expand((b) => b).toList();
        expect(allRows, [
          ['a', 'b'],
          ['c', 'd'],
          ['e', 'f'],
        ]);
      });
    });

    group('maxRowsPerBatch', () {
      test('maxRowsPerBatch: 1 emits single-row batches', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecLimited = csvFixed.asCodec(maxRowsPerBatch: 1);
        final inputSink =
            codecLimited.decoder.startChunkedConversion(outputSink);
        inputSink.add('a,b\r\nc,d\r\ne,f\r\n');
        inputSink.close();

        expect(batches.length, 3);
        expect(batches[0], [['a', 'b']]);
        expect(batches[1], [['c', 'd']]);
        expect(batches[2], [['e', 'f']]);
      });

      test('maxRowsPerBatch splits large chunk into capped batches', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecLimited = csvFixed.asCodec(maxRowsPerBatch: 3);
        final inputSink =
            codecLimited.decoder.startChunkedConversion(outputSink);

        // Send 10 rows in one chunk.
        final rows =
            '${List.generate(10, (i) => '$i,row$i').join('\r\n')}\r\n';
        inputSink.add(rows);
        inputSink.close();

        // 10 rows / 3 per batch = 3 full batches + 1 batch of 1
        expect(batches.length, 4);
        expect(batches[0].length, 3);
        expect(batches[1].length, 3);
        expect(batches[2].length, 3);
        expect(batches[3].length, 1);

        // Verify content is correct and ordered.
        final allRows = batches.expand((b) => b).toList();
        expect(allRows.length, 10);
        expect(allRows[0], ['0', 'row0']);
        expect(allRows[9], ['9', 'row9']);
      });

      test('maxRowsPerBatch larger than row count emits one batch', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecLimited = csvFixed.asCodec(maxRowsPerBatch: 100);
        final inputSink =
            codecLimited.decoder.startChunkedConversion(outputSink);
        inputSink.add('a,b\r\nc,d\r\n');
        inputSink.close();

        expect(batches.length, 1);
        expect(batches[0], [['a', 'b'], ['c', 'd']]);
      });

      test('maxRowsPerBatch works across multiple chunks', () {
        final batches = <List<List<dynamic>>>[];
        final outputSink = _CollectorSink<List<List<dynamic>>>(batches);

        final csvFixed = Csv(autoDetect: false);
        final codecLimited = csvFixed.asCodec(maxRowsPerBatch: 2);
        final inputSink =
            codecLimited.decoder.startChunkedConversion(outputSink);

        // Chunk 1: 3 rows → should emit batch of 2 + batch of 1.
        inputSink.add('a,1\r\nb,2\r\nc,3\r\n');
        // Chunk 2: 1 row → batch of 1.
        inputSink.add('d,4\r\n');
        inputSink.close();

        expect(batches.length, 3);
        expect(batches[0], [['a', '1'], ['b', '2']]);
        expect(batches[1], [['c', '3']]);
        expect(batches[2], [['d', '4']]);
      });

      test('convert() is unaffected by maxRowsPerBatch', () {
        final codecLimited = csv.asCodec(maxRowsPerBatch: 1);
        final result = codecLimited.decoder.convert('a,b\r\nc,d\r\ne,f');
        // convert() always returns all rows in one list.
        expect(result, [
          ['a', 'b'],
          ['c', 'd'],
          ['e', 'f'],
        ]);
      });
    });
  });
}

/// A simple sink that collects added items into a list.
class _CollectorSink<T> implements Sink<T> {
  final List<T> items;
  bool closed = false;

  _CollectorSink(this.items);

  @override
  void add(T data) {
    items.add(data);
  }

  @override
  void close() {
    closed = true;
  }
}

/// A trivial converter that counts rows in a `List<List<dynamic>>`.
class _RowCounter extends Converter<List<List<dynamic>>, int> {
  @override
  int convert(List<List<dynamic>> input) => input.length;
}
