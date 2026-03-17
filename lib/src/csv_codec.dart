import 'dart:convert';
import 'csv_encoder.dart';
import 'csv_decoder.dart';
import 'quote_mode.dart';
import 'csv_row.dart';

/// A CSV codec that provides encoding and decoding of CSV data.
///
/// This class does **not** extend `dart:convert`'s [Codec].
/// Dart's [Codec]/[Converter] type system requires the same type `T` for
/// both batch conversion and stream events, which is incompatible with CSV
/// where batch conversion returns `List<List<dynamic>>` but stream events
/// should be individual rows (`List<dynamic>`).
///
/// For stream usage, use [decoder] and [encoder] directly with
/// `Stream.transform()`:
/// ```dart
/// final rows = await file.openRead()
///     .transform(utf8.decoder)
///     .transform(csv.decoder)
///     .toList(); // List<List<dynamic>> — each element is one row
/// ```
///
/// If you need a `dart:convert` [Codec] (e.g., for [Codec.fuse]),
/// use [asCodec]. Be aware that the codec's stream behavior wraps rows
/// in an extra list layer (see [asCodec] documentation).
class Csv {
  final CsvEncoder _encoder;
  final CsvDecoder _decoder;

  /// Creates a [Csv] instance with the given parameters.
  ///
  /// [fieldDelimiter]: The separator between fields (default: ',').
  /// [lineDelimiter]: The separator between lines (default: '\r\n').
  /// [quoteCharacter]: The character used for quoting fields (default: '"').
  /// [escapeCharacter]: The character used for escaping quotes (defaults to [quoteCharacter]).
  /// [quoteMode]: Defines when fields should be quoted (default: [QuoteMode.necessary]).
  /// [addBom]: Whether to add a UTF-8 BOM when encoding (default: false).
  /// [autoDetect]: Whether to auto-detect the delimiter when decoding (default: true).
  /// [skipEmptyLines]: Whether to skip empty lines when decoding (default: true).
  /// [parseHeaders]: Whether to treat the first row as headers and return [CsvRow] objects (default: false).
  /// [encoderTransform]: A function to transform fields before encoding.
  /// [decoderTransform]: A function to transform fields after decoding.
  /// [dynamicTyping]: Whether to automatically parse numbers and booleans (default: false).
  Csv({
    String fieldDelimiter = ',',
    String lineDelimiter = '\r\n',
    String quoteCharacter = '"',
    String? escapeCharacter,
    QuoteMode quoteMode = QuoteMode.necessary,
    bool addBom = false,
    bool autoDetect = true,
    bool skipEmptyLines = true,
    bool parseHeaders = false,
    dynamic Function(dynamic field, int index, String? header)? encoderTransform,
    dynamic Function(dynamic field, int index, String? header)? decoderTransform,
    bool dynamicTyping = false,
  })  : _encoder = CsvEncoder(
          fieldDelimiter: fieldDelimiter,
          lineDelimiter: lineDelimiter,
          quoteCharacter: quoteCharacter,
          escapeCharacter: escapeCharacter,
          quoteMode: quoteMode,
          addBom: addBom,
          fieldTransform: encoderTransform,
        ),
        _decoder = CsvDecoder(
          fieldDelimiter: autoDetect ? null : fieldDelimiter,
          quoteCharacter: quoteCharacter,
          escapeCharacter: escapeCharacter,
          skipEmptyLines: skipEmptyLines,
          parseHeaders: parseHeaders,
          fieldTransform: decoderTransform,
          dynamicTyping: dynamicTyping,
        );

  /// Creates a [Csv] instance configured for Excel.
  ///
  /// This uses ';' as a field delimiter and adds a UTF-8 BOM.
  Csv.excel() : this(fieldDelimiter: ';', addBom: true, autoDetect: false);

  /// The CSV encoder.
  ///
  /// Can be used as a [StreamTransformer] where each input event is a
  /// single row (`List<dynamic>`) and each output event is a CSV string
  /// fragment.
  CsvEncoder get encoder => _encoder;

  /// The CSV decoder.
  ///
  /// Can be used as a [StreamTransformer] where each input event is a
  /// string chunk and each output event is a single row (`List<dynamic>`).
  CsvDecoder get decoder => _decoder;

  /// Encodes [rows] into a CSV string.
  String encode(List<List<dynamic>> rows) => _encoder.convert(rows);

  /// Decodes a CSV [input] string into a list of rows.
  List<List<dynamic>> decode(String input) => _decoder.convert(input);

  /// Decodes the given [encoded] CSV string into a list of [CsvRow]s.
  ///
  /// This automatically uses header parsing, returning a properly typed
  /// list of [CsvRow] objects, regardless of whether [parseHeaders]
  /// was set to true when creating this codec.
  List<CsvRow> decodeWithHeaders(String encoded) {
    if (_decoder.parseHeaders) {
      return _decoder.convert(encoded).cast<CsvRow>();
    }
    final decoder = CsvDecoder(
      fieldDelimiter: _decoder.fieldDelimiter,
      quoteCharacter: _decoder.quoteCharacter,
      escapeCharacter: _decoder.escapeCharacter,
      skipEmptyLines: _decoder.skipEmptyLines,
      fieldTransform: _decoder.fieldTransform,
      parseHeaders: true,
      dynamicTyping: _decoder.dynamicTyping,
    );
    return decoder.convert(encoded).cast<CsvRow>();
  }

  /// Returns a `dart:convert` [Codec] adapter for this CSV codec.
  ///
  /// This is useful when you need to use APIs that require a [Codec],
  /// such as [Codec.fuse].
  ///
  /// **Important**: The returned codec's [Converter] types follow Dart's
  /// `Converter<String, List<List<dynamic>>>` contract. When used as a
  /// [StreamTransformer], each stream event will be a `List<List<dynamic>>`
  /// (a batch of rows), **not** a single row. This means
  /// `stream.transform(codec.decoder).toList()` produces
  /// `List<List<List<dynamic>>>` — an extra layer of nesting.
  ///
  /// For stream usage, prefer using [decoder] and [encoder] directly.
  ///
  /// Example:
  /// ```dart
  /// // Fuse with another codec
  /// final fused = csv.asCodec().decoder.fuse(someConverter);
  /// ```
  Codec<List<List<dynamic>>, String> asCodec() => _CsvCodecAdapter(this);
}

/// Deprecated: Use [Csv] instead.
@Deprecated('Renamed to Csv. Will be removed in a future version.')
typedef CsvCodec = Csv;

/// A `dart:convert` [Codec] adapter that wraps a [Csv].
///
/// This provides the standard [Codec] interface with proper types,
/// at the cost of the stream nesting issue inherent in Dart's type system.
class _CsvCodecAdapter extends Codec<List<List<dynamic>>, String> {
  final Csv _csv;

  _CsvCodecAdapter(this._csv);

  @override
  Converter<String, List<List<dynamic>>> get decoder =>
      _CodecDecoderAdapter(_csv._decoder);

  @override
  Converter<List<List<dynamic>>, String> get encoder =>
      _CodecEncoderAdapter(_csv._encoder);
}

/// Wraps a [CsvDecoder] as a `Converter<String, List<List<dynamic>>>`.
class _CodecDecoderAdapter extends Converter<String, List<List<dynamic>>> {
  final CsvDecoder _decoder;

  _CodecDecoderAdapter(this._decoder);

  @override
  List<List<dynamic>> convert(String input) => _decoder.convert(input);

  @override
  Sink<String> startChunkedConversion(Sink<List<List<dynamic>>> sink) {
    // Wrap the batch sink so individual rows are collected into batches.
    return _decoder.startChunkedConversion(_BatchingSink(sink));
  }
}

/// Wraps a [CsvEncoder] as a `Converter<List<List<dynamic>>, String>`.
class _CodecEncoderAdapter extends Converter<List<List<dynamic>>, String> {
  final CsvEncoder _encoder;

  _CodecEncoderAdapter(this._encoder);

  @override
  String convert(List<List<dynamic>> input) => _encoder.convert(input);
}

/// A sink adapter that collects individual rows into batches before
/// forwarding them to a `Sink<List<List<dynamic>>>`.
///
/// This bridges the gap between the row-by-row output of [CsvDecoder]
/// and the batch-oriented `Converter` sink interface.
class _BatchingSink implements Sink<List<dynamic>> {
  final Sink<List<List<dynamic>>> _target;
  final _batch = <List<dynamic>>[];

  _BatchingSink(this._target);

  @override
  void add(List<dynamic> row) {
    _batch.add(row);
  }

  @override
  void close() {
    if (_batch.isNotEmpty) {
      _target.add(_batch.toList());
    }
    _target.close();
  }
}
