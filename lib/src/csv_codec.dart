import 'dart:convert';
import 'csv_encoder.dart';
import 'csv_decoder.dart';
import 'quote_mode.dart';
import 'csv_row.dart';

/// A [Codec] for CSV data.
class CsvCodec extends Codec<List<List<dynamic>>, String> {
  final CsvEncoder _encoder;
  final CsvDecoder _decoder;

  /// Creates a [CsvCodec] with the given parameters.
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
  CsvCodec({
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
        );

  /// Creates a [CsvCodec] configured for Excel.
  ///
  /// This uses ';' as a field delimiter and adds a UTF-8 BOM.
  CsvCodec.excel() : this(fieldDelimiter: ';', addBom: true, autoDetect: false);

  @override
  CsvEncoder get encoder => _encoder;

  @override
  CsvDecoder get decoder => _decoder;
}
