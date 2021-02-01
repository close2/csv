part of csv;

/// A Csv converter that returns the individual rows as lists of values.
///
/// This converter follows the rules of [rfc4180](http://tools.ietf.org/html/rfc4180).
///
/// See the [CsvParser] for more information.
class CsvToListConverter extends StreamTransformerBase<String, List>
    implements ComplexChunkedConverter<String, List<List>> {
  /// The separator between fields.
  final String? fieldDelimiter;

  /// The delimiter which (optionally) surrounds text / fields.
  final String? textDelimiter;

  /// The end delimiter for text.  This allows text to be quoted with different
  /// start / end delimiters: Example:  «abc».
  final String? textEndDelimiter;

  /// The end of line character which is expected after "row".
  ///
  /// The eol is optional for the last row.
  final String? eol;

  /// Should we try to parse unquoted text to numbers (int and doubles)
  final bool shouldParseNumbers;

  /// See [CsvParser.allowInvalid]
  final bool allowInvalid;

  /// An optional csvSettingsDetector.  See [CsvSettingsDetector].
  final CsvSettingsDetector? csvSettingsDetector;

  /// The default values for the optional arguments are consistent with
  /// [rfc4180](http://tools.ietf.org/html/rfc4180).
  ///
  /// Note that by default invalid values are allowed and no exceptions are
  /// thrown.
  const CsvToListConverter(
      {this.fieldDelimiter = defaultFieldDelimiter,
      String? textDelimiter = defaultTextDelimiter,
      String? textEndDelimiter,
      this.eol = defaultEol,
      this.csvSettingsDetector,
      bool? shouldParseNumbers,
      bool? allowInvalid})
      : this.textDelimiter = textDelimiter,
        this.textEndDelimiter =
            textEndDelimiter != null ? textEndDelimiter : textDelimiter,
        this.shouldParseNumbers =
            shouldParseNumbers != null ? shouldParseNumbers : true,
        this.allowInvalid = allowInvalid != null ? allowInvalid : true;

  /// Verifies current settings.
  ///
  /// Settings are not allowed to be null.  [fieldDelimiter], [textDelimiter],
  /// [eol] must be distinct and not the start of another parameter.
  /// For instance, if [fieldDelimiter] is ',' then [textDelimiter] may not be
  /// ',|,'.  If [textEndDelimiter] is different to [textDelimiter] the same
  /// rules apply.
  ///
  /// Returns either an empty list, if there are not errors, or a list of
  /// errors.  If [throwError] throws an error if a setting is invalid.
  List<ArgumentError> verifyCurrentSettings({bool? throwError}) {
    return verifySettings(fieldDelimiter, textDelimiter, textEndDelimiter, eol,
        throwError: throwError);
  }

  /// Verifies settings.
  ///
  /// Settings are not allowed to be null.  [fieldDelimiter], [textDelimiter],
  /// [eol] must be distinct and not the start of another parameter.
  /// For instance, if [fieldDelimiter] is ',' then [textDelimiter] may not be
  /// ',|,'.  If [textEndDelimiter] is different to [textDelimiter] the same
  /// rules apply.
  ///
  /// Returns either an empty list, if there are not errors, or a list of
  /// errors.  If [throwError] throws an error if a setting is invalid.
  static List<ArgumentError> verifySettings(String? fieldDelimiter,
      String? textDelimiter, String? textEndDelimiter, String? eol,
      {bool? throwError}) {
    return CsvParser.verifySettings(
        fieldDelimiter, textDelimiter, textEndDelimiter, eol);
  }

  // Implementation so that this converter can be used as transformer.
  /// [outputSink] must be of type Sink<List>.  (Strong mode prevents us from
  /// specifying the type here.)
  @override
  CsvToListSink startChunkedConversion(Sink outputSink) {
    return new CsvToListSink(
        outputSink as Sink<List>,
        fieldDelimiter,
        textDelimiter,
        textEndDelimiter,
        eol,
        csvSettingsDetector,
        shouldParseNumbers,
        allowInvalid);
  }

  /// Parses the [csv] and returns a List (rows) of Lists (columns).
  List<List> convert(String? csv,
      {String? fieldDelimiter,
      String? textDelimiter,
      String? textEndDelimiter,
      String? eol,
      CsvSettingsDetector? csvSettingsDetector,
      bool? shouldParseNumbers,
      bool? allowInvalid}) {
    fieldDelimiter ??= this.fieldDelimiter;
    textDelimiter ??= this.textDelimiter;
    textEndDelimiter ??= this.textEndDelimiter;
    eol ??= this.eol;
    csvSettingsDetector ??= this.csvSettingsDetector;
    shouldParseNumbers ??= this.shouldParseNumbers;
    allowInvalid ??= this.allowInvalid;

    var parser = _buildNewParserWithSettings(
        [csv],
        true,
        csvSettingsDetector,
        fieldDelimiter,
        textDelimiter,
        textEndDelimiter,
        eol,
        shouldParseNumbers,
        allowInvalid)!;

    return parser.convert(csv);
  }

  Stream<List> bind(Stream<String> stream) {
    return new Stream<List>.eventTransformed(stream,
        (EventSink sink) => new ComplexConverterStreamEventSink(this, sink));
  }
}

CsvParser? _buildNewParserWithSettings(
    List<String?> unparsedCsvChunks,
    bool? noMoreChunks,
    CsvSettingsDetector? csvSettingsDetector,
    String? fieldDelimiter,
    String? textDelimiter,
    String? textEndDelimiter,
    String? eol,
    bool shouldParseNumbers,
    bool allowInvalid) {
  if (csvSettingsDetector != null) {
    var settings = csvSettingsDetector.detectFromCsvChunks(
        unparsedCsvChunks, noMoreChunks);

    if (settings.needMoreData! && !noMoreChunks!) return null;

    fieldDelimiter = settings.fieldDelimiter ?? fieldDelimiter;
    textDelimiter = settings.textDelimiter ?? textDelimiter;
    textEndDelimiter = settings.textEndDelimiter ?? textEndDelimiter;
    eol = settings.eol ?? eol;
  }

  return new CsvParser(
      fieldDelimiter: fieldDelimiter,
      textDelimiter: textDelimiter,
      textEndDelimiter: textEndDelimiter,
      eol: eol,
      shouldParseNumbers: shouldParseNumbers,
      allowInvalid: allowInvalid);
}

/// The input sink for a chunked csv-string to list conversion.
class CsvToListSink extends ChunkedConversionSink<String> {
  /// Rows converted to Lists are added to this sink.
  final Sink<List> _outSink;

  /// The csv parser which has the configurations (delimiter, eol,...) already
  /// set.
  CsvParser? _parser;

  List<String?> _unparsedCsvChunks;

  List _currentRow;

  final String? _fieldDelimiter;
  final String? _textDelimiter;
  final String? _textEndDelimiter;
  final String? _eol;
  final CsvSettingsDetector? _csvSettingsDetector;
  bool _shouldParseNumbers;
  bool _allowInvalid;

  CsvToListSink(
      this._outSink,
      this._fieldDelimiter,
      this._textDelimiter,
      this._textEndDelimiter,
      this._eol,
      this._csvSettingsDetector,
      this._shouldParseNumbers,
      this._allowInvalid)
      : _currentRow = [],
        _unparsedCsvChunks = [];

  _add(String? newCsvChunk, {bool? fieldCompleteWhenEndOfString}) {
    newCsvChunk ??= '';
    _unparsedCsvChunks.add(newCsvChunk);

    // Unless this is the last chunk (fieldCompleteWhenEndOfString) we might
    // have to wait for another chunk to autodetect / find the first occurrence
    // of a setting string.
    if (_parser == null) {
      _parser = _buildNewParserWithSettings(
          _unparsedCsvChunks,
          fieldCompleteWhenEndOfString,
          _csvSettingsDetector,
          _fieldDelimiter,
          _textDelimiter,
          _textEndDelimiter,
          _eol,
          _shouldParseNumbers,
          _allowInvalid);
      assert(_parser != null || !fieldCompleteWhenEndOfString!);
      if (_parser == null) return; // and wait for another chunk
    }

    for (int i = 0; i < _unparsedCsvChunks.length; ++i) {
      String? csvChunk = _unparsedCsvChunks[i];

      final isLastCsvChunk = (i + 1) == _unparsedCsvChunks.length;

      bool continueCsv = false;

      // Parse rows until EndOfString.
      for (;;) {
        final end = isLastCsvChunk && fieldCompleteWhenEndOfString!;
        final result = _parser!.convertRow(csvChunk, _currentRow,
            continueCsv: continueCsv, fieldCompleteWhenEndOfString: end);

        continueCsv = true;

        if (result.stopReason == ParsingStopReason.EndOfString) {
          if (_currentRow.isNotEmpty && end) {
            _outSink.add(_currentRow);
          }
          break;
        }
        _outSink.add(_currentRow);
        _currentRow = [];
      }
    }
    _unparsedCsvChunks.clear();
  }

  @override
  add(String csvChunk) {
    _add(csvChunk, fieldCompleteWhenEndOfString: false);
  }

  @override
  close() {
    _add(null, fieldCompleteWhenEndOfString: true);

    _outSink.close();
  }
}
