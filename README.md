# csv

A high-quality, best-practice CSV library for Dart, inspired by PapaParse but built with Dart idioms in mind.

## Upgrading from Version 6
Version 7 is a complete rewrite and introduces breaking changes.
If you rely on the specific flexibility of version 6 (e.g., complex eol handling not supported here),
please consult [doc/README-v6.md](doc/README-v6.md) and continue using version 6.

## Features

- **Darty API**: Fully implements `Codec` and `Converter` interfaces from `dart:convert`.
- **Easy Excel Compatibility**: Built-in support for Excel-compatible CSVs (UTF-8 BOM, `;` separator, `\r\n` line endings).
- **Auto-detection**: Smartly detects delimiters and line endings.
- **Robust Parsing**: Handles quoted fields, escaped quotes, and even malformed CSVs graciously (similar to PapaParse).
- **Performance**: Optimized for speed and low memory usage.


### Delimiters

The `CvCodec` and `CsvDecoder` support:
*   **Field Delimiters**: Can be single or multi-character strings (e.g., `,`, `::`, `|`).
*   **Quote Character**: Must be a **single character**. Defaults to `"`.
*   **Escape Character**: Must be a **single character** (if provided). Defaults to the quote character.
*   **Line Delimiters**: The decoder automatically handles `\r`, `\n`, and `\r\n`. The encoder allows specifying a custom `lineDelimiter` (defaults to `\r\n`).

## Usage

### Simple Example

```dart
import 'package:csv/csv.dart';

void main() {
  final data = [
    ['Name', 'Age', 'City'],
    ['Alice', 30, 'New York'],
    ['Bob', 25, 'London'],
  ];

  // Encode
  final String csvString = csv.encode(data);
  print(csvString);

  // Decode
  final List<List<dynamic>> decodedData = csv.decode(csvString);
  print(decodedData);
}
```

### Excel Compatible CSV

Excel often requires a UTF-8 BOM and `;` as a separator to open files correctly in certain locales.

```dart
import 'package:csv/csv.dart';

void main() {
  final data = [
    ['Header1', 'Header2'],
    ['Value 1', 'Value 2'],
  ];

  // Use the built-in excel codec
  final String excelCsv = excel.encode(data);
  
  // This automatically adds the BOM and uses ';' as delimiter
}
```

### Custom Configuration

```dart
import 'package:csv/csv.dart';

void main() {
  final myCodec = CsvCodec(
    fieldDelimiter: '\t',
    lineDelimiter: '\n',
    quoteMode: QuoteMode.strings, // Only quote strings, not numbers
    escapeCharacter: '\\',       // Use backslash for escaping
  );
  
  final encoded = myCodec.encode([['a', 1, true], ['b', 2.5, false]]);
  // Output: "a",1,true\n"b",2.5,false
}
```

### Advanced: Field Transformations

You can use the `encoderTransform` and `decoderTransform` hooks to process fields based on their value, column index, or header name to for example trim text, change decimal separators or format dates.

```dart
import 'package:csv/csv.dart';

void main() {
  final customCodec = CsvCodec(
    fieldDelimiter: ';',
    parseHeaders: true, // Required if you want 'header' name in the transform
    decoderTransform: (value, index, header) {
      // Change column 3 (index 2) to uppercase
      if (index == 2) return value.toUpperCase();
      
      // Convert 'Age' column to int
      if (header == 'Age') return int.tryParse(value) ?? value;
      
      return value;
    },
  );

  final input = 'Name;City;Age\nAlice;London;30';
  final decoded = customCodec.decode(input);
  
  print(decoded[0]['Age']);   // 30 (as int)
  print(decoded[0]['City']);  // LONDON
}
```

### Automated Delimiter Detection (including sep=;)

The library automatically detects common delimiters (`,`, `;`, `\t`, `|`). It also respects the `sep=;` header common in some Excel-exported CSV files.

```dart
final decoded = csv.decode('sep=;\r\nA;B;C');
// Result: [['A', 'B', 'C']]
```

### Map-like Row Access

If you want to access values by their header names, use the `parseHeaders` option. It returns `CsvRow` objects which behave like both a `List` and a `Map`.

```dart
import 'package:csv/csv.dart';

void main() {
  final fileContents = 'id,name\n1,Alice\n2,Bob';
  final codec = CsvCodec(parseHeaders: true);
  
  final rows = codec.decode(fileContents);
  
  // Access by header name
  print(rows[0]['name']); // Alice
  
  // Still accessible by index
  print(rows[0][1]);      // Alice
  
  // The first row of the file was used for headers and is not in the list.
}
```

### Stream Transformation (Read-Modify-Write)

You can use `fuse` to combine the encoder and decoder, or simply chain transformations to process large files efficiently.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

void main() async {
  final input = File('input.csv');
  final output = File('output.csv');

  await input.openRead()
      .transform(utf8.decoder)
      .transform(csv.decoder)
      .map((row) {
        // Modify the row
        row.add('Processed');
        return row;
      })
      .transform(csv.encoder)
      .transform(utf8.encoder)
      .pipe(output.openWrite());
}
```

### Fusing Codecs

You can also fuse the `csv.encoder` and `csv.decoder` (or any other compatible codecs) to create a new codec.

```dart
import 'dart:convert';
import 'package:csv/csv.dart';

void main() {
  // Create a codec that converts List<List> -> String -> List<List>
  // Ideally this is an identity transformation (Round Trip).
  final fused = csv.encoder.fuse(csv.decoder);
  
  final data = [['a', 'b'], ['c', 'd']];
  final result = fused.convert(data);
  print(result); // [['a', 'b'], ['c', 'd']]
}
```

### Advanced Fusing: Processing Pipeline

You can create a `Codec` that reads a CSV string, processes the data, and outputs a new CSV string by fusing the decoder, a custom processor, and the encoder.

```dart
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
  
  // Let's create a "Processing Codec" that takes String and returns String (CSV -> CSV)
  // We start with the decoder (String -> List)
  // Fuse with processor (List -> List)
  // Fuse with encoder (List -> String)
  
  final sanitizingCodec = csv.decoder.fuse(processor).fuse(csv.encoder);

  final inputCsv = 'Name,Age\nAlice,30';
  final outputCsv = sanitizingCodec.convert(inputCsv);

  print(outputCsv);
  // Output:
  // Name,Age,Processed
  // Alice,30,Processed
}
```


## PapaParse Features

This library incorporates many good ideas from PapaParse, such as:
- Handling misplaced quotes gracefully.
- Auto-detecting delimiters based on frequency and consistency.
- Handling various line ending styles automatically in the decoder.
- Support for `sep=` headers.
- Header Parsing: Efficiently mapping headers to row indices (similar to `header: true` in PapaParse).

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  csv: ^7.0.0
```
