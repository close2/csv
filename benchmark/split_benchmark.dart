
import 'dart:convert';
import 'package:csv/csv.dart';

void main() {
  final stopwatch = Stopwatch();
  
  // 1. Generate a large CSV
  final rowCount = 10000;
  final buffer = StringBuffer();
  for (int i = 0; i < rowCount; i++) {
    buffer.write('1,"Row $i with ""quotes"" inside",3.14\r\n');
  }
  final hugeCsv = buffer.toString();
  print('Generated CSV size: ${hugeCsv.length} bytes');

  // Warmup
  _runDecoder(hugeCsv);
  _runDecoderSplit(hugeCsv, 10);

  // 2. Measure single chunk performance
  stopwatch.start();
  for (int i = 0; i < 10; i++) {
    _runDecoder(hugeCsv);
  }
  stopwatch.stop();
  print('Single chunk (10 runs): ${stopwatch.elapsedMilliseconds} ms');

  // 3. Measure split chunk performance (simulating stream)
  stopwatch.reset();
  stopwatch.start();
  // Split into chunks of size 5
  for (int i = 0; i < 10; i++) {
    _runDecoderSplit(hugeCsv, 5);
  }
  stopwatch.stop();
  print('Split chunks (size 5, 10 runs): ${stopwatch.elapsedMilliseconds} ms');
}

void _runDecoder(String input) {
  final decoder = CsvDecoder();
  decoder.convert(input);
}

void _runDecoderSplit(String input, int chunkSize) {
  final outSink = ChunkedConversionSink<List<List<dynamic>>>.withCallback((
    x,
  ) {});
  final inputSink = CsvDecoder().startChunkedConversion(outSink);
  
  for (int i = 0; i < input.length; i += chunkSize) {
    final end = (i + chunkSize < input.length) ? i + chunkSize : input.length;
    inputSink.add(input.substring(i, end));
  }
  inputSink.close();
}
