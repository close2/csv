part of csv;



/// Converts a csv string into a List of rows.  Each row is represented
/// by a List.
///
/// This converter follows the rules of [rfc4180](http://tools.ietf.org/html/rfc4180).
///
/// See the [CsvParser] for more information.
class CsvToListConverter extends Converter<String, List<List>> implements StreamTransformer {

  /// The separator between fields.
  final String fieldDelimiter;

  /// The delimiter which (optionally) surrounds text / fields.
  final String textDelimiter;

  /// The end delimiter for text.  This allows text to be quoted with different
  /// start / end delimiters: Example:  «abc».
  final String textEndDelimiter;

  /// The end of line character which is expected after "row".
  ///
  /// The eol is optional for the last row.
  final String eol;

  /// Should we try to parse unquoted text to numbers (int and doubles)
  final bool parseNumbers;


  /// See [CsvParser.allowInvalid]
  final bool allowInvalid;

  
  /// An optional csvSettingsDetector.  See [CsvSettingsDetector].
  final CsvSettingsDetector csvSettingsDetector;

  
  /// The default values for the optional arguments are consistend with
  /// [rfc4180](http://tools.ietf.org/html/rfc4180).
  ///
  /// Note that by default invalid values are allowed and no exceptions are
  /// thrown.
  const CsvToListConverter({this.fieldDelimiter: defaultFieldDelimiter,
                           String textDelimiter: defaultTextDelimiter,
                           String textEndDelimiter,
                           this.eol: defaultEol,
                           this.csvSettingsDetector,
                           bool parseNumbers,
                           bool allowInvalid})
      : this.textDelimiter = textDelimiter,
        this.textEndDelimiter = textEndDelimiter != null ?
                                textEndDelimiter :
                                textDelimiter,
        this.parseNumbers = parseNumbers != null ? parseNumbers : true,
        this.allowInvalid = allowInvalid != null ? allowInvalid : true;



  /// Implementation so that this converter can be used as transformer.
  @override
  CsvToListSink startChunkedConversion(Sink<List> outputSink) {

    return new CsvToListSink(outputSink,
                             fieldDelimiter,
                             textDelimiter,
                             textEndDelimiter,
                             eol,
                             csvSettingsDetector,
                             parseNumbers,
                             allowInvalid);
  }


  /// Parses the [csv] and returns a List (rows) of Lists (columns).
  @override
  List<List> convert(String csv,
                     {String fieldDelimiter,
                      String textDelimiter,
                      String textEndDelimiter,
                      String eol,
                      CsvSettingsDetector csvSettingsDetector,
                      bool parseNumbers,
                      bool allowInvalid}) {
    if (fieldDelimiter == null) fieldDelimiter = this.fieldDelimiter;
    if (textDelimiter == null) textDelimiter = this.textDelimiter;
    if (textEndDelimiter == null) textEndDelimiter = this.textEndDelimiter;
    if (eol == null) eol = this.eol;
    if (csvSettingsDetector == null) {
      csvSettingsDetector = this.csvSettingsDetector;
    }
    if (parseNumbers == null) parseNumbers = this.parseNumbers;
    if (allowInvalid == null) allowInvalid = this.allowInvalid;

    
    var parser = _buildNewParserWithSettings([csv],
                                             true,
                                             csvSettingsDetector,
                                             fieldDelimiter,
                                             textDelimiter,
                                             textEndDelimiter,
                                             eol,
                                             parseNumbers,
                                             allowInvalid);

    return parser.convert(csv);
  }
}


CsvParser _buildNewParserWithSettings(List<String> unparsedCsvChunks,
                                      bool noMoreChunks,
                                      CsvSettingsDetector csvSettingsDetector,
                                      String fieldDelimiter,
                                      String textDelimiter,
                                      String textEndDelimiter,
                                      String eol,
                                      bool parseNumbers,
                                      bool allowInvalid) {
    if (csvSettingsDetector != null) {
      var settings = csvSettingsDetector.detectFromCsvChunks(unparsedCsvChunks,
                                                             noMoreChunks);
      
      if (settings.needMoreData && !noMoreChunks) return null;
    
      var ifNotNull = (String value, String defaultValue) {
        return value != null ? value : defaultValue;
      };
      
      fieldDelimiter = ifNotNull(settings.fieldDelimiter, fieldDelimiter);
      textDelimiter = ifNotNull(settings.textDelimiter, textDelimiter);
      textEndDelimiter = ifNotNull(settings.textEndDelimiter,
                                   textEndDelimiter);
      eol = ifNotNull(settings.eol, eol);
    }
    
    return new CsvParser(fieldDelimiter: fieldDelimiter,
                         textDelimiter: textDelimiter,
                         textEndDelimiter: textEndDelimiter,
                         eol: eol,
                         parseNumbers: parseNumbers,
                         allowInvalid: allowInvalid);
}

/// The input sink for a chunked csv-string to list conversion.
class CsvToListSink extends ChunkedConversionSink<String> {

  /// Rows converted to Lists are added to this sink.
  final Sink<List> _outSink;

  /// This is the csv parser which has the configurations
  /// (delimiter, eol,...) already set.
  CsvParser _parser;

  List<String> _unparsedCsvChunks;

  List _currentRow;


  final String _fieldDelimiter;
  final String _textDelimiter;
  final String _textEndDelimiter;
  final String _eol;
  final CsvSettingsDetector _csvSettingsDetector;
  bool _parseNumbers;
  bool _allowInvalid;

  CsvToListSink(this._outSink,
                this._fieldDelimiter,
                this._textDelimiter,
                this._textEndDelimiter,
                this._eol,
                this._csvSettingsDetector,
                this._parseNumbers,
                this._allowInvalid)
      : _currentRow = [],
        _unparsedCsvChunks = [];


  _add(String newCsvChunk, {bool fieldCompleteWhenEndOfString}) {

    if (newCsvChunk == null) newCsvChunk = '';
    _unparsedCsvChunks.add(newCsvChunk);

    // Unless this is the last chunk (fieldCompleteWhenEndOfString) we might
    // have to wait for another chunk to autodetect / find the first occurence
    // of a setting string.
    if (_parser == null) {
      _parser = _buildNewParserWithSettings(_unparsedCsvChunks,
                                            fieldCompleteWhenEndOfString,
                                            _csvSettingsDetector,
                                            _fieldDelimiter,
                                            _textDelimiter,
                                            _textEndDelimiter,
                                            _eol,
                                            _parseNumbers,
                                            _allowInvalid);
      assert(_parser != null || !fieldCompleteWhenEndOfString);
      if (_parser == null) return;  // and wait for another chunk
    }


    for (int i = 0; i < _unparsedCsvChunks.length; ++i) {

      String csvChunk = _unparsedCsvChunks[i];

      final lastCsvChunk = (i + 1) == _unparsedCsvChunks.length;

      bool continueCsv = false;

      // parse rows until EndOfString
      for (;;) {
        final end = lastCsvChunk && fieldCompleteWhenEndOfString;
        final result = _parser.convertRow(csvChunk,
                                          _currentRow,
                                          continueCsv: continueCsv,
                                          fieldCompleteWhenEndOfString: end);

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
