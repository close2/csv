import 'dart:async';
import 'quote_mode.dart';
import 'csv_row.dart';

/// A stream transformer and batch converter that encodes rows into CSV strings.
///
/// When used as a [StreamTransformer] (e.g., with `Stream.transform()`),
/// each incoming stream event should be a single row (`List<dynamic>`),
/// and each outgoing event is a CSV string fragment.
///
/// The [convert] method accepts all rows at once as a `List<List<dynamic>>`
/// and returns the full CSV string.
class CsvEncoder extends StreamTransformerBase<List<dynamic>, String> {
  /// The separator between fields.
  final String fieldDelimiter;

  /// The separator between lines.
  final String lineDelimiter;

  /// The character used for quoting fields.
  final String quoteCharacter;

  /// The character used for escaping characters inside quoted fields.
  final String escapeCharacter;

  /// Defines how fields are quoted.
  final QuoteMode quoteMode;

  /// Whether to add a UTF-8 BOM at the beginning (for Excel).
  final bool addBom;

  /// The function that can be used to transform each field before encoding.
  final dynamic Function(dynamic field, int index, String? header)? fieldTransform;

  /// Creates a [CsvEncoder].
  ///
  /// The [fieldDelimiter] defaults to ','.
  /// The [lineDelimiter] defaults to '\r\n'.
  /// The [quoteCharacter] defaults to '"'.
  /// The [escapeCharacter] defaults to [quoteCharacter].
  /// [quoteMode] defaults to [QuoteMode.necessary].
  /// [addBom] defaults to false.
  const CsvEncoder({
    this.fieldDelimiter = ',',
    this.lineDelimiter = '\r\n',
    this.quoteCharacter = '"',
    String? escapeCharacter,
    this.quoteMode = QuoteMode.necessary,
    this.addBom = false,
    this.fieldTransform,
  }) : escapeCharacter = escapeCharacter ?? quoteCharacter;

  /// Converts all [rows] into a CSV string.
  String convert(List<List<dynamic>> rows) {
    if (rows.isEmpty) return addBom ? '\ufeff' : '';

    final buffer = StringBuffer();
    if (addBom) {
      buffer.write('\ufeff');
    }

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      _writeRow(buffer, row);
      if (i < rows.length - 1) {
        buffer.write(lineDelimiter);
      }
    }
    return buffer.toString();
  }

  void _writeRow(StringBuffer buffer, List<dynamic> row) {
    final isCsvRow = row is CsvRow;
    for (var j = 0; j < row.length; j++) {
      if (j > 0) {
        buffer.write(fieldDelimiter);
      }
      final String? header = isCsvRow ? row.getHeaderName(j) : null;
      buffer.write(
        encodeField(
          row[j],
          fieldDelimiter,
          quoteCharacter,
          escapeCharacter,
          quoteMode,
          fieldTransform,
          j,
          header,
        ),
      );
    }
  }

  @override
  Stream<String> bind(Stream<List<dynamic>> stream) {
    return Stream<String>.eventTransformed(
      stream,
      (EventSink<String> sink) => _EncoderEventSink(this, sink),
    );
  }

  /// Encodes a single [field] into its CSV string representation.
  ///
  /// This method handles quoting based on the provided [quoteMode]:
  /// - [QuoteMode.always]: Every field is wrapped in quotes.
  /// - [QuoteMode.strings]: Only [String] types are quoted.
  /// - [QuoteMode.necessary]: Fields are quoted only if they contain delimiters,
  ///   newlines, quotes, or leading/trailing spaces.
  static String encodeField(
    dynamic field,
    String fieldDelimiter,
    String quoteCharacter,
    String escapeCharacter,
    QuoteMode quoteMode,
    dynamic Function(dynamic field, int index, String? header)? transform,
    int index,
    String? header,
  ) {
    if (transform != null) {
      field = transform(field, index, header);
    }
    if (field == null) return '';

    final String stringValue = field.toString();

    bool needsQuotes;
    switch (quoteMode) {
      case QuoteMode.always:
        needsQuotes = true;
        break;
      case QuoteMode.strings:
        needsQuotes = field is String;
        break;
      case QuoteMode.necessary:
        // A field needs quoting if it contains special characters or whitespace.
        needsQuotes =
            stringValue.contains(fieldDelimiter) ||
            stringValue.contains('\n') ||
            stringValue.contains('\r') ||
            stringValue.contains(quoteCharacter) ||
            stringValue.startsWith(' ') ||
            stringValue.endsWith(' ');
        break;
    }

    if (needsQuotes) {
      // Escape the quote character by prefixing it with the escape character.
      final escaped = stringValue.replaceAll(
        quoteCharacter,
        '$escapeCharacter$quoteCharacter',
      );
      return '$quoteCharacter$escaped$quoteCharacter';
    }

    return stringValue;
  }
}

/// An [EventSink] adapter for the encoder that accepts individual rows
/// and outputs CSV string fragments.
class _EncoderEventSink implements EventSink<List<dynamic>> {
  final CsvEncoder _encoder;
  final EventSink<String> _eventSink;
  bool _isFirstRow = true;

  _EncoderEventSink(this._encoder, this._eventSink);

  @override
  void add(List<dynamic> row) {
    final buffer = StringBuffer();
    if (_isFirstRow) {
      if (_encoder.addBom) {
        buffer.write('\ufeff');
      }
      _isFirstRow = false;
    } else {
      buffer.write(_encoder.lineDelimiter);
    }
    _encoder._writeRow(buffer, row);
    _eventSink.add(buffer.toString());
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _eventSink.close();
  }
}
