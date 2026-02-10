import 'dart:async';
import 'package:csv/csv.dart';

void main() async {
  print('--- CSV Benchmark ---');

  await runBenchmark('Default CSV', csv);
  await runBenchmark('Excel CSV', excel);
  await runBenchmark('Tab CSV', CsvCodec(fieldDelimiter: '\t'));

  await runFuseBenchmark('Fused Codec (Round Trip)', csv);
}

Future<void> runBenchmark(String name, CsvCodec codec) async {
  print('\n--- $name ---');

  const targetSizeBytes = 100 * 1024 * 1024; // 100 MB
  const chunkSize = 1000;
  
  final sampleRow = [
    'field1', 12345, 12.345,
    'This is a slightly longer field.',
    'Field with "quotes" and , commas',
    true, null
  ];
  
  final estimatedRowSize = codec.encode([sampleRow]).length;
  final totalRows = (targetSizeBytes / estimatedRowSize).floor();

  // Encoding
  final encodeStopwatch = Stopwatch()..start();
  var encodedBytes = 0;
  final encodeController = StreamController<List<List<dynamic>>>();
  final encodingStream = encodeController.stream.transform(codec.encoder);
  final encodingFuture = encodingStream.listen((data) => encodedBytes += data.length).asFuture();

  for (var i = 0; i < totalRows; i += chunkSize) {
    final nextChunkRows = (totalRows - i) > chunkSize ? chunkSize : (totalRows - i);
    final chunk = List.generate(nextChunkRows, (_) => sampleRow);
    encodeController.add(chunk);
  }
  await encodeController.close();
  await encodingFuture;
  encodeStopwatch.stop();

  // Decoding
  final decodeStopwatch = Stopwatch()..start();
  var decodedRows = 0;
  final decodeController = StreamController<String>();
  final decodingStream = decodeController.stream.transform(codec.decoder);
  final decodingFuture = decodingStream.listen((chunk) => decodedRows += chunk.length).asFuture();

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

Future<void> runFuseBenchmark(String name, CsvCodec codec) async {
  print('\n--- $name ---');
  
  // Fuse encoder and decoder: List<List> -> String -> List<List>
  // Note: CsvCodec is Codec<List<List>, String>.
  // codec.encoder is Converter<List<List>, String>.
  // codec.decoder is Converter<String, List<List>>.
  // fused = codec.encoder.fuse(codec.decoder); // Converter<List<List>, List<List>>
  
  final fused = codec.encoder.fuse(codec.decoder);

  const targetSizeBytes = 50 * 1024 * 1024; // 50 MB (smaller for round-trip)
  const chunkSize = 1000;
  
  final sampleRow = [
    'field1', 12345, 12.345,
    'This is a slightly longer field.',
    'Field with "quotes" and , commas',
    true, null
  ];
  
  final estimatedRowSize = codec.encode([sampleRow]).length;
  final totalRows = (targetSizeBytes / estimatedRowSize).floor();

  final stopwatch = Stopwatch()..start();
  var processedRows = 0;
  
  final controller = StreamController<List<List<dynamic>>>();
  final stream = controller.stream.transform(fused);
  final future = stream.listen((chunk) {
    processedRows += chunk.length;
  }).asFuture();

  for (var i = 0; i < totalRows; i += chunkSize) {
    final nextChunkRows = (totalRows - i) > chunkSize ? chunkSize : (totalRows - i);
    final chunk = List.generate(nextChunkRows, (_) => sampleRow);
    controller.add(chunk);
  }
  await controller.close();
  await future;
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
