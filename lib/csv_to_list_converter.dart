part of csv;



/// Converts a csv string into a List of rows.  Each row is represented
/// by a List.
///
/// This converter follows the rules of [rfc4180](http://tools.ietf.org/html/rfc4180).
///
/// See the [CsvParser] for more information.
class Csv2ListConverter extends Converter<String, List<List>> implements StreamTransformer {

  /// The separator between fields.
  final String fieldDelimiter;

  /// The delimiter which (optionally) surrounds text / fields.
  final String textDelimiter;

  /// The end delimiter for text.  This allows text to be quoted with different
  /// start / end delimiters: Example:  «abc».
  /// If [textEndDelimiter] is null, [textDelimiter] is used instead;
  final String textEndDelimiter;

  /// The end of line character which is expected after "row".
  ///
  /// The eol is optional for the last row.
  final String eol;

  /// Should we try to parse unquoted text to numbers (int and doubles)
  final bool parseNumbers;


  /// See [CsvParser.allowInvalid]
  final bool allowInvalid;


  /// The default values for the optional arguments are consistend with
  /// [rfc4180](http://tools.ietf.org/html/rfc4180).
  ///
  /// Note that by default invalid values are allowed and no exceptions are
  /// thrown.
  const Csv2ListConverter({this.fieldDelimiter: defaultFieldDelimiter,
                           String textDelimiter: defaultTextDelimiter,
                           String textEndDelimiter,
                           this.eol: defaultEol,
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
  Csv2ListSink startChunkedConversion(Sink<List> outputSink) {

    var parser = new CsvParser(fieldDelimiter: fieldDelimiter,
                               textDelimiter: textDelimiter,
                               textEndDelimiter: textEndDelimiter,
                               eol: eol,
                               parseNumbers: parseNumbers,
                               allowInvalid: allowInvalid);

    return new Csv2ListSink(parser, outputSink);
  }


  /// Parses the [csv] and returns a List (rows) of Lists (columns).
  @override
  List<List> convert(String csv,
                     {String fieldDelimiter,
                      String textDelimiter,
                      String textEndDelimiter,
                      String eol,
                      bool parseNumbers,
                      bool allowInvalid}) {
    if (fieldDelimiter == null) fieldDelimiter = this.fieldDelimiter;
    if (textDelimiter == null) textDelimiter = this.textDelimiter;
    if (textEndDelimiter == null) textEndDelimiter = this.textEndDelimiter;
    if (eol == null) eol = this.eol;
    if (parseNumbers == null) parseNumbers = this.parseNumbers;
    if (allowInvalid == null) allowInvalid = this.allowInvalid;

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
class Csv2ListSink extends ChunkedConversionSink<String> {

  /// Rows converted to Lists are added to this sink.
  final Sink<List> _outSink;

  /// This is the csv parser which has the configurations
  /// (delimiter, eol,...) already set.
  final CsvParser _parser;

  List _currentRow;

  Csv2ListSink(this._parser, this._outSink)
      : _currentRow = [];


  _add(String csvChunk, {bool fieldCompleteWhenEndOfString}) {

    bool continueCsv = false;

    for (;;) {

      final result = _parser.convertRow(csvChunk,
                                        _currentRow,
                                        continueCsv: continueCsv,
                                        fieldCompleteWhenEndOfString:
                                          fieldCompleteWhenEndOfString);

      continueCsv = true;

      if (result.stopReason == ParsingStopReason.EndOfString) {
        if (_currentRow.isNotEmpty && fieldCompleteWhenEndOfString) {
          _outSink.add(_currentRow);
        }
        break;
      }

      _outSink.add(_currentRow);
      _currentRow = [];
    }
  }

  @override
  add(String csvChunk) {
    _add(csvChunk, fieldCompleteWhenEndOfString: false);
  }

  @override
  close() {
    _add(null, fieldCompleteWhenEndOfString: true);

    // TODO check if not inside quoted string.
    _outSink.close();
  }
}
