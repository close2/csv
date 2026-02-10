import 'dart:convert';
import 'quote_mode.dart';
import 'csv_row.dart';

/// A converter that converts a [List<List<dynamic>>] into a CSV string.
class CsvEncoder extends Converter<List<List<dynamic>>, String> {
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

  @override
  String convert(List<List<dynamic>> input) {
    if (input.isEmpty) return addBom ? '\ufeff' : '';

    final output = <String>[];
    final outSink = ChunkedConversionSink<String>.withCallback(
      (result) => output.addAll(result),
    );
    final sink = startChunkedConversion(outSink);
    sink.add(input);
    sink.close();
    return output.join();
  }

  @override
  ChunkedConversionSink<List<List<dynamic>>> startChunkedConversion(
    Sink<String> sink,
  ) {
    return _CsvEncoderSink(
      sink,
      fieldDelimiter,
      lineDelimiter,
      quoteCharacter,
      escapeCharacter,
      quoteMode,
      addBom,
      fieldTransform,
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

class _CsvEncoderSink implements ChunkedConversionSink<List<List<dynamic>>> {
  final Sink<String> _outSink;
  final String _fieldDelimiter;
  final String _lineDelimiter;
  final String _quoteCharacter;
  final String _escapeCharacter;
  final QuoteMode _quoteMode;
  final bool _addBom;
  final dynamic Function(dynamic field, int index, String? header)? _fieldTransform;
  bool _isFirstChunk = true;

  _CsvEncoderSink(
    this._outSink,
    this._fieldDelimiter,
    this._lineDelimiter,
    this._quoteCharacter,
    this._escapeCharacter,
    this._quoteMode,
    this._addBom,
    this._fieldTransform,
  );

  @override
  void add(List<List<dynamic>> chunk) {
    if (chunk.isEmpty) return;

    final buffer = StringBuffer();
    if (_isFirstChunk) {
      if (_addBom) {
        buffer.write('\ufeff');
      }
      _isFirstChunk = false;
    } else {
      buffer.write(_lineDelimiter);
    }

    for (var i = 0; i < chunk.length; i++) {
      final row = chunk[i];
      final isCsvRow = row is CsvRow;
      for (var j = 0; j < row.length; j++) {
        if (j > 0) {
          buffer.write(_fieldDelimiter);
        }
        final String? header = isCsvRow ? row.getHeaderName(j) : null;
        buffer.write(
          CsvEncoder.encodeField(
            row[j],
            _fieldDelimiter,
            _quoteCharacter,
            _escapeCharacter,
            _quoteMode,
            _fieldTransform,
            j,
            header,
          ),
        );
      }
      if (i < chunk.length - 1) {
        buffer.write(_lineDelimiter);
      }
    }
    _outSink.add(buffer.toString());
  }

  @override
  void close() {
    _outSink.close();
  }
}
