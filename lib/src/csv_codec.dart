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
  /// **Batching behavior**: When the codec's decoder is used for chunked
  /// conversion (i.e., as a stream transformer), rows decoded from the same
  /// input chunk are forwarded together as a single batch. This preserves
  /// natural chunk boundaries and avoids creating a new list for every row.
  ///
  /// Use [maxRowsPerBatch] to cap the number of rows in each emitted batch.
  /// This prevents a single large input chunk from producing a huge list.
  /// For example, `maxRowsPerBatch: 1` gives single-row batches (one event
  /// per row). When `null` (the default), all rows from a chunk are emitted
  /// together.
  ///
  /// Example:
  /// ```dart
  /// // Fuse with another codec
  /// final fused = csv.asCodec().decoder.fuse(someConverter);
  ///
  /// // Limit batch size to 100 rows
  /// final codec = csv.asCodec(maxRowsPerBatch: 100);
  /// ```
  Codec<List<List<dynamic>>, String> asCodec({int? maxRowsPerBatch}) {
    assert(
      maxRowsPerBatch == null || maxRowsPerBatch > 0,
      'maxRowsPerBatch must be positive',
    );
    return _CsvCodecAdapter(this, maxRowsPerBatch: maxRowsPerBatch);
  }
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
  final int? _maxRowsPerBatch;

  _CsvCodecAdapter(this._csv, {int? maxRowsPerBatch})
      : _maxRowsPerBatch = maxRowsPerBatch;

  @override
  Converter<String, List<List<dynamic>>> get decoder =>
      _CodecDecoderAdapter(_csv._decoder, maxRowsPerBatch: _maxRowsPerBatch);

  @override
  Converter<List<List<dynamic>>, String> get encoder =>
      _CodecEncoderAdapter(_csv._encoder);
}

/// Wraps a [CsvDecoder] as a `Converter<String, List<List<dynamic>>>`.
class _CodecDecoderAdapter extends Converter<String, List<List<dynamic>>> {
  final CsvDecoder _decoder;
  final int? _maxRowsPerBatch;

  _CodecDecoderAdapter(this._decoder, {int? maxRowsPerBatch})
      : _maxRowsPerBatch = maxRowsPerBatch;

  @override
  List<List<dynamic>> convert(String input) => _decoder.convert(input);

  @override
  Sink<String> startChunkedConversion(Sink<List<List<dynamic>>> sink) {
    final collector = _RowCollector(sink, _maxRowsPerBatch);
    final decoderSink = _decoder.startChunkedConversion(collector);
    return _ChunkBoundaryInputSink(decoderSink, collector);
  }
}

/// Wraps a [CsvEncoder] as a `Converter<List<List<dynamic>>, String>`.
class _CodecEncoderAdapter extends Converter<List<List<dynamic>>, String> {
  final CsvEncoder _encoder;

  _CodecEncoderAdapter(this._encoder);

  @override
  String convert(List<List<dynamic>> input) => _encoder.convert(input);
}

/// A [StringConversionSink] wrapper that flushes collected rows after each
/// input chunk, establishing natural chunk-based batch boundaries.
class _ChunkBoundaryInputSink extends StringConversionSink {
  final StringConversionSink _inner;
  final _RowCollector _collector;

  _ChunkBoundaryInputSink(this._inner, this._collector);

  @override
  void add(String chunk) {
    _inner.add(chunk);
    _collector.flush();
  }

  @override
  void addSlice(String chunk, int start, int end, bool isLast) {
    _inner.addSlice(chunk, start, end, isLast);
    if (isLast) {
      // close() on the inner sink was already triggered by addSlice with
      // isLast=true, which will call _collector.close(). No extra flush.
    } else {
      _collector.flush();
    }
  }

  @override
  void close() {
    _inner.close();
    // _inner.close() calls _collector.close(), which flushes remaining rows.
  }
}

/// Collects individual rows and forwards them as batches to the target sink.
///
/// Rows are accumulated until [flush] is called (typically at chunk
/// boundaries) or until the batch reaches [_maxRowsPerBatch], whichever
/// comes first.
class _RowCollector implements Sink<List<dynamic>> {
  final Sink<List<List<dynamic>>> _target;
  final int? _maxRowsPerBatch;
  final _batch = <List<dynamic>>[];

  _RowCollector(this._target, this._maxRowsPerBatch);

  @override
  void add(List<dynamic> row) {
    _batch.add(row);
    final max = _maxRowsPerBatch;
    if (max != null && _batch.length >= max) {
      _emitBatch();
    }
  }

  /// Flushes any accumulated rows as a single batch.
  void flush() {
    if (_batch.isNotEmpty) {
      _emitBatch();
    }
  }

  void _emitBatch() {
    _target.add(_batch.toList());
    _batch.clear();
  }

  @override
  void close() {
    flush();
    _target.close();
  }
}
