
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  group('Split Chunk Escape Tests', () {
    test('Splitting escaped quote at every position', () {
      const input = 'a,"b""c",d';
      final expected = [
        ['a', 'b"c', 'd']
      ];
      _verifySplit(input, expected);
    });

    // Case that definitely fails if bug exists
    test('Splitting escaped quote with comma', () {
       const input = 'a,"b"",c",d';
       final expected = [
         ['a', 'b",c', 'd']
       ];
       _verifySplit(input, expected);
    });
  });
}

void _verifySplit(String input, List<List<dynamic>> expected,
    {String? escapeChar}) {
  for (int i = 0; i <= input.length; i++) {
    final chunk1 = input.substring(0, i);
    final chunk2 = input.substring(i);

    final output = <List<dynamic>>[];
    final outSink = ChunkedConversionSink<List<List<dynamic>>>.withCallback((
      accumulated,
    ) {
      for (final rows in accumulated) {
        output.addAll(rows);
      }
    });

    // IMPORTANT: Set fieldDelimiter to prevent auto-detection buffering
    final decoderSink = CsvDecoder(
            escapeCharacter: escapeChar, 
            fieldDelimiter: ',')
        .startChunkedConversion(outSink);

    if (chunk1.isNotEmpty) decoderSink.add(chunk1);    
    if (chunk2.isNotEmpty) decoderSink.add(chunk2);
    decoderSink.close();

    expect(
      output,
      expected,
      reason: 'Failed when split at index $i.\n'
          'Chunk 1: "$chunk1"\n'
          'Chunk 2: "$chunk2"',
    );
  }
}
