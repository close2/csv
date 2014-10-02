part of csv;



/// Converts a csv string into a List of rows.  Each row is represented
/// by a List.
///
/// This converter follows the rules of [rfc4180](http://tools.ietf.org/html/rfc4180).
///
/// See the [CsvParser] for more information.
class CsvToListConverter extends Converter<String, List<List>> implements StreamTransformer {

  /// The separator between fields.
  final List<String> fieldDelimiters;

  /// The delimiter which (optionally) surrounds text / fields.
  final List<String> textDelimiters;

  /// The end delimiter for text.  This allows text to be quoted with different
  /// start / end delimiters: Example:  «abc».
  /// If [textEndDelimiter] is null, [textDelimiter] is used instead;
  final List<String> textEndDelimiters;

  /// The end of line character which is expected after "row".
  ///
  /// The eol is optional for the last row.
  final List<String> eols;

  /// Should we try to parse unquoted text to numbers (int and doubles)
  final bool parseNumbers;


  /// See [CsvParser.allowInvalid]
  final bool allowInvalid;


  static List<String> _prep(setting, [alternativeSetting]) {
    if (setting != null && setting is List) return setting;
    if (setting != null && setting is String) return [setting];
    if (alternativeSetting != null && alternativeSetting is List)
      return alternativeSetting;
    if (alternativeSetting != null && alternativeSetting is String)
      return [alternativeSetting];
    return [null];
  }

  /// The default values for the optional arguments are consistend with
  /// [rfc4180](http://tools.ietf.org/html/rfc4180).
  ///
  /// Note that by default invalid values are allowed and no exceptions are
  /// thrown.
  CsvToListConverter({fieldDelimiters: defaultFieldDelimiter,
                      textDelimiters: defaultTextDelimiter,
                      textEndDelimiters,
                      eols: defaultEol,
                      bool parseNumbers,
                      bool allowInvalid})
      : this.fieldDelimiters = _prep(fieldDelimiters),
        this.textDelimiters = _prep(textDelimiters),
        this.textEndDelimiters = _prep(textEndDelimiters,
                                       textDelimiters),
        this.eols = _prep(eols),
        this.parseNumbers = parseNumbers != null ? parseNumbers : true,
        this.allowInvalid = allowInvalid != null ? allowInvalid : true;



  /// Implementation so that this converter can be used as transformer.
  @override
  CsvToListSink startChunkedConversion(Sink<List> outputSink) {

    return new CsvToListSink(outputSink,
                             fieldDelimiters,
                             textDelimiters,
                             textEndDelimiters,
                             eols,
                             parseNumbers,
                             allowInvalid);
  }


  /// Parses the [csv] and returns a List (rows) of Lists (columns).
  @override
  List<List> convert(String csv,
                     {fieldDelimiters,
                      textDelimiters,
                      textEndDelimiters,
                      eols,
                      bool parseNumbers,
                      bool allowInvalid}) {
    fieldDelimiters = _prep(fieldDelimiters, this.fieldDelimiters);
    textDelimiters = _prep(textDelimiters, this.textDelimiters);
    textEndDelimiters = _prep(textEndDelimiters, this.textEndDelimiters);
    eols = _prep(eols, this.eols);
    if (parseNumbers == null) parseNumbers = this.parseNumbers;
    if (allowInvalid == null) allowInvalid = this.allowInvalid;

    final fieldDelimiter = _findFirst(csv, fieldDelimiters)._match;
    final textDelimiter = _findFirst(csv, textDelimiters)._match;
    final textEndDelimiter = _findFirst(csv, textEndDelimiters)._match;
    final eol = _findFirst(csv, eols)._match;

    var parser = new CsvParser(fieldDelimiter: fieldDelimiter,
                               textDelimiter: textDelimiter,
                               textEndDelimiter: textEndDelimiter,
                               eol: eol,
                               parseNumbers: parseNumbers,
                               allowInvalid: allowInvalid);

    return parser.convert(csv);
  }
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


  final _fieldDelimiters;
  final _textDelimiters;
  final _textEndDelimiters;
  final _eols;
  bool _parseNumbers;
  bool _allowInvalid;

  CsvToListSink(this._outSink,
                this._fieldDelimiters,
                this._textDelimiters,
                this._textEndDelimiters,
                this._eols,
                this._parseNumbers,
                this._allowInvalid)
      : _currentRow = [],
        _unparsedCsvChunks = [];


  _add(String newCsvChunk, {bool fieldCompleteWhenEndOfString}) {

    if (newCsvChunk == null) newCsvChunk = '';
    _unparsedCsvChunks.add(newCsvChunk);

    if (_parser == null) {
      final fieldMatch = _findFirst(_unparsedCsvChunks, _fieldDelimiters);
      final textMatch = _findFirst(_unparsedCsvChunks, _textDelimiters);
      final textEndMatch = _findFirst(_unparsedCsvChunks, _textEndDelimiters);
      final eolMatch = _findFirst(_unparsedCsvChunks, _eols);
      if (!fieldCompleteWhenEndOfString &&
          (fieldMatch._index == null ||
           textMatch._index == null ||
           textEndMatch._index == null ||
           eolMatch._index == null)) return; // and wait for another chunk.
      _parser = new CsvParser(fieldDelimiter: fieldMatch._match,
                              textDelimiter: textMatch._match,
                              textEndDelimiter: textEndMatch._match,
                              eol: eolMatch._match,
                              parseNumbers: _parseNumbers,
                              allowInvalid: _allowInvalid);
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



class _FirstMatch {
  final String _match;
  final int _index;

  const _FirstMatch(this._match, this._index);
}

_FirstMatch _findFirst(csvStringOrList, List<String> possibleValues) {
  // This is definitely not the fastest way!
  // We can however not simply check every chunk on its own, as a possibleValue
  // might span 2 (or more) chunks.

  if (csvStringOrList == null) csvStringOrList = '';

  final csv = csvStringOrList is String ?
              csvStringOrList :
              (csvStringOrList as List<String>).join();

  if (possibleValues.length == 1) {
    return new _FirstMatch(possibleValues.first, 0);
  }

  var bestMatchIndex = csv.length;
  var bestMatch = possibleValues.first;

  // This is definitely not the fastest way!
  // We can however not simply check every
  possibleValues.forEach((val) {
    if (val == null) return;

    final currentIndex = csv.indexOf(val);

    if (currentIndex != -1 && currentIndex < bestMatchIndex) {
      bestMatchIndex = currentIndex;
      bestMatch = val;
    }

  });

  final int retIndex = bestMatchIndex == csv.length ?
                       null:
                       bestMatchIndex;
  return new _FirstMatch(bestMatch, retIndex);
}

