import 'dart:async';
import 'package:csv/csv.dart';

void main() async {
  print('--- CSV Benchmark ---');

  await runBenchmark('Default CSV', csv);
  await runBenchmark('Dynamic Typing CSV', Csv(dynamicTyping: true));
  await runBenchmark('Excel CSV', excel);
  await runBenchmark('Tab CSV', Csv(fieldDelimiter: '\t'));

  await runFuseBenchmark('Fused Codec (Round Trip)', csv);
}

Future<void> runBenchmark(String name, Csv codec) async {
  print('\n--- $name ---');

  const targetSizeBytes = 100 * 1024 * 1024; // 100 MB
  const chunkSize = 1000;
  
  final sampleRow = <dynamic>[
    'field1', 12345, 12.345,
    'This is a slightly longer field.',
    'Field with "quotes" and , commas',
    true, null
  ];
  
  final estimatedRowSize = codec.encode([sampleRow]).length;
  final totalRows = (targetSizeBytes ~/ estimatedRowSize);

  // Encoding — stream of individual rows
  final encodeStopwatch = Stopwatch()..start();
  var encodedBytes = 0;
  final encodeController = StreamController<List<dynamic>>();
  final encodingStream = encodeController.stream.transform(codec.encoder);
  final encodingFuture = encodingStream.listen((data) => encodedBytes += data.length).asFuture();

  for (var i = 0; i < totalRows; i++) {
    encodeController.add(sampleRow);
  }
  await encodeController.close();
  await encodingFuture;
  encodeStopwatch.stop();

  // Decoding — stream emits individual rows
  final decodeStopwatch = Stopwatch()..start();
  var decodedRows = 0;
  final decodeController = StreamController<String>();
  final decodingStream = decodeController.stream.transform(codec.decoder);
  final decodingFuture = decodingStream.listen((_) => decodedRows++).asFuture();

  for (var i = 0; i < totalRows; i += chunkSize) {
    final nextChunkRows = (totalRows - i) > chunkSize ? chunkSize : (totalRows - i);
    final chunk = List.generate(nextChunkRows, (_) => sampleRow);
    final encodedChunk = codec.encode(chunk);
    decodeController.add(encodedChunk);
  }
  await decodeController.close();
  await decodingFuture;
  decodeStopwatch.stop();

  final mb = encodedBytes / (1024 * 1024);
  final encTime = encodeStopwatch.elapsedMilliseconds;
  final decTime = decodeStopwatch.elapsedMilliseconds;
  
  print(' - Enc: ${(mb / (encTime / 1000)).toStringAsFixed(2)} MB/s ($encTime ms)');
  print(' - Dec: ${(mb / (decTime / 1000)).toStringAsFixed(2)} MB/s ($decTime ms)');
}

Future<void> runFuseBenchmark(String name, Csv codec) async {
  print('\n--- $name ---');
  
  // Use asCodec() to get a dart:convert Codec for fusing.
  final dartCodec = codec.asCodec();
  final fused = dartCodec.encoder.fuse(dartCodec.decoder);

  const targetSizeBytes = 50 * 1024 * 1024; // 50 MB (smaller for round-trip)
  const chunkSize = 1000;
  
  final sampleRow = <dynamic>[
    'field1', 12345, 12.345,
    'This is a slightly longer field.',
    'Field with "quotes" and , commas',
    true, null
  ];
  
  final estimatedRowSize = codec.encode([sampleRow]).length;
  final totalRows = (targetSizeBytes ~/ estimatedRowSize);

  final stopwatch = Stopwatch()..start();
  var processedRows = 0;
  
  // fused.convert() works batch-style on List<List<dynamic>>
  for (var i = 0; i < totalRows; i += chunkSize) {
    final nextChunkRows = (totalRows - i) > chunkSize ? chunkSize : (totalRows - i);
    final chunk = List.generate(nextChunkRows, (_) => sampleRow);
    final result = fused.convert(chunk);
    processedRows += result.length;
  }
  stopwatch.stop();

  if (processedRows != totalRows) {
    print('Error: Processed $processedRows rows, expected $totalRows');
  } else {
    print('Round-trip successful: $processedRows rows');
  }

  final mb = (totalRows * estimatedRowSize) / (1024 * 1024);
  final time = stopwatch.elapsedMilliseconds;
  print(' - Round Trip: ${(mb / (time / 1000)).toStringAsFixed(2)} MB/s ($time ms)');
}
