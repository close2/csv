# csv

A high-quality, best-practice CSV library for Dart, inspired by PapaParse but built with Dart idioms in mind.

## Upgrading from Version 7
Version 8 fixes an issue where using `csv.decoder` as a stream transformer
produced an extra layer of nesting ([#77](https://github.com/close2/csv/issues/77)).

- `CsvCodec` has been renamed to `Csv`. A deprecated `CsvCodec` typedef is
  available for migration.
- `Csv` no longer extends `dart:convert`'s `Codec` class. If you need a `Codec`
  (e.g., for `.fuse()`), use [`asCodec()`](#the-codec-problem--ascodec).

If you rely on the version 6 API, please consult [doc/README-v6.md](doc/README-v6.md).

## Features

- **Stream-friendly**: `decoder` and `encoder` are proper `StreamTransformer`s — one row per stream event.
- **Easy Excel Compatibility**: Built-in support for Excel-compatible CSVs (UTF-8 BOM, `;` separator, `\r\n` line endings).
- **Auto-detection**: Smartly detects delimiters and line endings.
- **Robust Parsing**: Handles quoted fields, escaped quotes, and even malformed CSVs graciously (similar to PapaParse).
- **Performance**: Optimized for speed and low memory usage.
- **Dynamic Typing**: Optional automatic parsing of numbers and booleans (similar to PapaParse).


### Delimiters

The `Csv` class and `CsvDecoder` support:
*   **Field Delimiters**: Can be single or multi-character strings (e.g., `,`, `::`, `|`).
*   **Quote Character**: Must be a **single character**. Defaults to `"`.
*   **Escape Character**: Must be a **single character** (if provided). Defaults to the quote character.
*   **Line Delimiters**: The decoder automatically handles `\r`, `\n`, and `\r\n`. The encoder allows specifying a custom `lineDelimiter` (defaults to `\r\n`).

## ⚠️ Important: Line Endings & Windows

The default line delimiter is `\r\n` (CRLF) as specified by RFC 4180.

**Be careful on Windows!**
If you write the CSV string directly to a file using certain methods (like `File.writeAsString` without specifying strict options or redirecting `stdout`), Windows file handling might automatically convert `\n` to `\r\n`. Since the CSV already contains `\r\n`, this can result in double carriage returns: `\r\r\n`.

To avoid this, either:
1.  **Use `\n` as the line delimiter:**
    ```dart
    final codec = Csv(lineDelimiter: '\n');
    final csvString = codec.encode(data);
    ```
2.  **Use a binary writer** (e.g., `File.openWrite()`) which writes bytes exactly as they are.

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

### Stream Transformation (e.g., reading a file)

The decoder and encoder are `StreamTransformer`s that emit **one row per event**,
so `stream.transform(csv.decoder).toList()` gives you a flat `List<List<dynamic>>`.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

void main() async {
  final file = File('data.csv');

  // Each event in the stream is a single row (List<dynamic>).
  final List<List<dynamic>> rows = await file
      .openRead()
      .transform(utf8.decoder)
      .transform(csv.decoder)
      .toList();

  print(rows.first); // e.g. ['Name', 'Age', 'City']
}
```

### Stream Read-Modify-Write Pipeline

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
        row.add('Processed');
        return row;
      })
      .transform(csv.encoder)
      .transform(utf8.encoder)
      .pipe(output.openWrite());
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
  final myCodec = Csv(
    fieldDelimiter: '\t',
    lineDelimiter: '\n',
    quoteMode: QuoteMode.strings, // Only quote strings, not numbers
    escapeCharacter: '\\',       // Use backslash for escaping
  );
  
  final encoded = myCodec.encode([['a', 1, true], ['b', 2.5, false]]);
  // Output: "a"\t1\ttrue\n"b"\t2.5\tfalse
}
```

### Dynamic Typing

Automatically convert values that look like numbers or booleans into their respective Dart types.

> [!NOTE]
> Enabling `dynamicTyping` adds a small performance overhead (approx. 15% in benchmarks). For maximum performance on large files where you know the schema, using a manual `decoderTransform` or processing rows after decoding is faster.

```dart
import 'package:csv/csv.dart';

void main() {
  final input = 'Name,Age,Active\nAlice,30,true';
  
  // With dynamic typing enabled
  final codec = Csv(dynamicTyping: true);
  final rows = codec.decode(input);
  
  print(rows[0][1].runtimeType); // int (30)
  print(rows[0][2].runtimeType); // bool (true)
}
```

### Advanced: Field Transformations

You can use the `encoderTransform` and `decoderTransform` hooks to process fields based on their value, column index, or header name to for example trim text, change decimal separators or format dates.

```dart
import 'package:csv/csv.dart';

void main() {
  final customCodec = Csv(
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

If you want to access values by their header names, you can use either `decodeWithHeaders()` or the `parseHeaders` option on the codec. Both return `CsvRow` objects which behave like both a `List` and a `Map`.

```dart
import 'package:csv/csv.dart';

void main() {
  final fileContents = 'id,name\n1,Alice\n2,Bob';
  
  // Method 1: Using decodeWithHeaders (Recommended)
  // This automatically sets the parseHeaders flag and returns a properly typed List<CsvRow>.
  final rowsWithHeaders = csv.decodeWithHeaders(fileContents);
  
  // Access by header name directly
  print(rowsWithHeaders[0]['name']); // Alice
  
  // Still accessible by index
  print(rowsWithHeaders[0][1]);      // Alice
  
  
  // Method 2: Using Csv(parseHeaders: true)
  // This requires casting the returned rows to CsvRow manually.
  final codec = Csv(parseHeaders: true);
  
  final dynamicRows = codec.decode(fileContents);
  
  final row = dynamicRows[0] as CsvRow;
  // Access by header name
  print(row['name']); // Alice
  
  // The first row of the file was used for headers and is not in the list.
}
```

### Using `asCodec()` for Fusing

If you need a `dart:convert` `Codec` — for example, to use `.fuse()` — call `asCodec()`:

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

  // Use asCodec() to get a dart:convert Codec, then fuse.
  final codec = csv.asCodec();
  final sanitizingCodec = codec.decoder.fuse(processor).fuse(codec.encoder);

  final inputCsv = 'Name,Age\nAlice,30';
  final outputCsv = sanitizingCodec.convert(inputCsv);

  print(outputCsv);
  // Output:
  // Name,Age,Processed
  // Alice,30,Processed
}
```

**Controlling batch size**: When the codec's decoder is used as a stream
transformer, rows from the same input chunk are emitted together in a single
batch (a `List<List<dynamic>>`). You can limit the maximum number of rows per
batch with `maxRowsPerBatch`:

```dart
// Each stream event contains at most 100 rows.
final codec = csv.asCodec(maxRowsPerBatch: 100);

// For single-row events (one row per stream event), use 1:
final singleRowCodec = csv.asCodec(maxRowsPerBatch: 1);
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
  csv: ^8.0.0
```

## The Codec Problem & `asCodec()`

This section explains why `Csv` does **not** extend `dart:convert`'s `Codec`,
and what `asCodec()` provides as an escape hatch.

### Background

Dart's `Codec<S, T>` provides two converters:

| Component | Type              |
|-----------|-------------------|
| `decoder` | `Converter<T, S>` |
| `encoder` | `Converter<S, T>` |

A `Converter<S, T>` has two roles:

1. **Batch**: `T convert(S input)` — convert an entire input at once.
2. **Stream**: `Stream<T> bind(Stream<S>)` — transform a stream, where each event is of type `T`.

The type parameter `T` must serve **both** roles. For most codecs this is fine.
For example, `utf8` is a `Codec<String, List<int>>`: batch conversion produces a
`List<int>`, and each stream event is also a `List<int>` (a chunk of bytes).
Concatenating chunks of bytes is natural.

### Why CSV breaks this

For a CSV decoder, the two roles need **different types**:

| Role                | Needs                                            |
|---------------------|--------------------------------------------------|
| Batch (`convert()`) | Returns `List<List<dynamic>>` — all rows at once |
| Stream (each event) | Should be `List<dynamic>` — one row at a time    |

There is no single type `T` that works for both. If we use
`Converter<String, List<List<dynamic>>>` (as version 7 did), then:

- `convert("a,b\nc,d")` → `[['a','b'], ['c','d']]` ✓ correct
- `stream.transform(decoder).toList()` → `List<List<List<dynamic>>>` ✗ **extra nesting!**

Each stream event is a *batch* of rows, and `.toList()` collects those batches
into yet another list — the "extra `[]`" reported in [#77](https://github.com/close2/csv/issues/77).

This is a fundamental limitation of `dart:convert`'s type system, not a bug in
this library. Versions 3.2 through 6 worked around it by not being a `Codec` at
all (see [commit 235d898](https://github.com/close2/csv/commit/235d89854b86ef9f2e2e864d138ce96ab38b4a0d)).
Version 7 reintroduced `Codec` and the problem came back.

### The solution in version 8

Version 8 takes a hybrid approach:

- **By default**, `CsvDecoder` and `CsvEncoder` are `StreamTransformerBase`
  subclasses. Stream usage works correctly — one row per event.
- **`asCodec()`** returns a real `Codec<List<List<dynamic>>, String>` adapter for
  when you need `.fuse()` or other `Codec`-specific APIs. The returned codec
  wraps the same parsing/encoding logic, but follows Dart's `Converter` type
  contract (with the inherent stream nesting trade-off).

```dart
// Default: stream works correctly
final rows = await file.openRead()
    .transform(utf8.decoder)
    .transform(csv.decoder)
    .toList();
// rows is List<List<dynamic>> ✓

// asCodec(): for fuse() and other Codec APIs
final fused = csv.asCodec().decoder.fuse(someConverter);

// asCodec() with batch size limit
final codec = csv.asCodec(maxRowsPerBatch: 100);
```

If you use `asCodec().decoder` as a stream transformer, you will get the extra
nesting — that is inherent to Dart's `Converter` type contract and cannot be
avoided. Rows from the same input chunk are grouped together into a single batch.
Use `maxRowsPerBatch` to limit the batch size, or use `csv.decoder` directly for
streams.
