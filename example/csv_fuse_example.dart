import 'dart:convert';
import 'package:csv/csv.dart';

// A simple converter that adds a column to every row.
class AddColumnConverter extends Converter<List<List<dynamic>>, List<List<dynamic>>> {
  @override
  List<List<dynamic>> convert(List<List<dynamic>> input) {
    return input.map((row) => [...row, 'Processed']).toList();
  }
}

void main() {
  final processor = AddColumnConverter();

  // Create a pipeline: CSV String -> List<List> -> Modified List<List> -> CSV String
  // Use asCodec() to get a dart:convert Codec for fusing.
  final codec = csv.asCodec();
  final sanitizingCodec = codec.decoder.fuse(processor).fuse(codec.encoder);

  final inputCsv = 'Name,Age\nAlice,30';
  final outputCsv = sanitizingCodec.convert(inputCsv);

  print(outputCsv);
  // Output:
  // Name,Age,Processed
  // Alice,30,Processed
}
