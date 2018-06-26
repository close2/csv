part of csv;

/// Converts rows -- a [List] of [List]s into a csv String.
///
///
/// This converter follows the rules of
/// [rfc4180](http://tools.ietf.org/html/rfc4180).
/// Except for the possibility to override the separator character
/// ([fieldDelimiter]), the text delimiter ([textDelimiter]) and the [eol]
/// string.
///
/// The existence of a field delimiter, text delimiter or eol is determined
/// by checking *every* character _on it's own_ if the value is longer than
/// one character.
///
/// For instance if the overridden field delimiter is _'<->'_ and a field
/// contains *either* '<' or '-' or '>' the conversion code follows the RFC as
/// if the character the value overrides is present.  (This is also the case
/// for the default [eol] \r\n and follows the RFC).
/// In this example it means, that any field which contains either '<', '-' or
/// '>' must be quoted (rule 6).
///
/// For Rule 7 and [textDelimiter]s with multiple characters the above
/// statement is still correct, but only complete [textDelimiter] are preceded
/// with another [textDelimiter].
///
///
/// Ad rule 3: removed as it is not relevant for this converter.
/// Ad rule 5: text-delimiters are only used when necessary.
///
///
/// Chapter 2, Definition of the CSV Format:
///
/// 1. Each record is located on a separate line, delimited by a line break
///    (CRLF).  For example:
///     aaa,bbb,ccc CRLF
///     zzz,yyy,xxx CRLF
///
/// 2. The last record in the file may or may not have an ending line break.
///    For example:
///     aaa,bbb,ccc CRLF
///     zzz,yyy,xxx
///
/// 3. ... (Header-lines)
///
/// 4. Within the header and each record, there may be one or more fields,
///    separated by commas.  Each line should contain the same number of
///    fields throughout the file.  Spaces are considered part of a field and
///    should not be ignored.  The last field in the record must not be
///    followed by a comma.  For example:
///
///     aaa,bbb,ccc
///
/// 5. Each field may or may not be enclosed in double quotes (however some
///    programs, such as Microsoft Excel, do not use double quotes at all).
///    If fields are not enclosed with double quotes, then double quotes may
///    not appear inside the fields.  For example:
///
///     "aaa","bbb","ccc" CRLF
///     zzz,yyy,xxx
///
/// 6. Fields containing line breaks (CRLF), double quotes, and commas should
///    be enclosed in double-quotes.  For example:
///
///     "aaa","b CRLF
///     bb","ccc" CRLF
///     zzz,yyy,xxx
///
/// 7. If double-quotes are used to enclose fields, then a double-quote
///    appearing inside a field must be escaped by preceding it with another
///    double quote.  For example:
///
///     "aaa","b""bb","ccc"
class ListToCsvConverter extends StreamTransformerBase<List, String>
    implements ComplexChunkedConverter<List<List>, String> {
  /// The separator between fields in the outputString.
  final String fieldDelimiter;

  /// The delimiter which surrounds text / fields which have a
  /// [fieldDelimiter] in the text representation.
  ///
  /// If for instance the [fieldDelimiter] is »_,_«, the [textDelimiter]
  /// is »_"_« and a field is »_some text, with a comma_« the output would be
  ///  »_"some text, with a comma"_«.
  final String textDelimiter;

  final String textEndDelimiter;

  /// The end of line character which is inserted after every "row".
  ///
  /// The [convert] function expects a [List] of [List]s.
  /// The inner [List]s represent one row.  So we have a [List] of rows.
  /// When converting to String, every row ([List]) is converted on its
  /// own and appended to the previous one with this separator.
  final String eol;

  /// Add delimiter to all fields, even if the field does not contain any
  /// character, which would adding delimiters necessary.
  final bool delimitAllFields;

  /// The default values for [fieldDelimiter], [textDelimiter] and [eol]
  /// are consistent with [rfc4180](http://tools.ietf.org/html/rfc4180).
  ///
  const ListToCsvConverter(
      {this.fieldDelimiter: defaultFieldDelimiter,
      String textDelimiter: defaultTextDelimiter,
      String textEndDelimiter,
      this.eol: defaultEol,
      this.delimitAllFields: defaultDelimitAllFields})
      : this.textDelimiter = textDelimiter,
        this.textEndDelimiter =
            textEndDelimiter != null ? textEndDelimiter : textDelimiter;

  /// Converts rows -- a [List] of [List]s into a csv String.
  ///
  /// According to [rfc4180](http://tools.ietf.org/html/rfc4180).
  ///
  /// [fieldDelimiter], [textDelimiter], [eol] and [delimitAllFields] allow to
  /// override the default rfc values.  If an optional argument is not given
  /// (or null) its corresponding .this value ([this.fieldDelimiter],
  /// [this.textDelimiter] or [this.eol]) is used instead.
  ///
  /// All other rfc rules are followed.
  ///
  /// If [rows] is null an empty String is returned.
  String convert(List<List> rows,
      {String fieldDelimiter,
      String textDelimiter,
      String textEndDelimiter,
      String eol,
      bool delimitAllFields}) {
    if (rows == null) return '';

    eol ??= this.eol;

    if (eol == null) {
      throw new ArgumentError('Eol string must not be null');
    }

    var sb = new StringBuffer();
    var sep = '';
    rows.forEach((r) {
      sb.write(sep);
      sep = eol;
      convertSingleRow(sb, r,
          fieldDelimiter: fieldDelimiter,
          textDelimiter: textDelimiter,
          textEndDelimiter: textEndDelimiter,
          eol: eol,
          delimitAllFields: delimitAllFields);
    });
    return sb.toString();
  }

  /// Returns an input Sink into which the caller may [add](List2CsvSink.add)
  /// single rows.  A single row is a List.  The signature of the input sink
  /// is therefore: add(List).
  ///
  /// The row, converted to csv, is then added to the [outputSink], row by
  /// row.
  /// Every single row added to the outputSink has an eol.
  ///
  /// The output to [convert] differs to this chunked conversion by the last
  /// character. The chunked conversion has an additional eol whereas the
  /// [convert] function does not output an eol for the last line.  Note that
  /// the rfc says, that the eol for the last row is optional.  Which means
  /// that the output is still rfc conform.
  ///
  /// [outputSink] must be of type Sink<String>.  (Strong mode prevents us from
  /// specifying the type here.)
  @override
  List2CsvSink startChunkedConversion(Sink<String> outputSink) {
    return new List2CsvSink(this, outputSink);
  }

  /// Converts a list of values representing a row into a value separated
  /// string.
  ///
  /// If [rowValues] is empty or null, returns "".
  ///
  /// If the optional [fieldDelimiter] and [textDelimiter] is not specified
  /// (null) uses [this.fieldDelimiter] and [this.textDelimiter].
  ///
  /// All values of the [rowValues] are joined with [fieldDelimiter].  If such
  /// a value contains the [fieldDelimiter] itself the value is surrounded
  /// with [textDelimiter].
  ///
  /// If in such a case the value also contains [textDelimiter] those
  /// [textDelimiter] instances are doubled (see _Definition of the CSV
  /// Format_ Rule 7 [rfc4180](http://tools.ietf.org/html/rfc4180)).
  String convertSingleRow(StringBuffer sb, List rowValues,
      {String fieldDelimiter,
      String textDelimiter,
      String textEndDelimiter,
      String eol,
      bool delimitAllFields}) {
    if (rowValues == null || rowValues.isEmpty) return '';

    fieldDelimiter ??= this.fieldDelimiter;
    // assign given textDelimiter to textEndDelimiter
    textEndDelimiter ??= textDelimiter;
    textDelimiter ??= this.textDelimiter;
    // if textDelimiter was null use the default textEndDelimiter
    textEndDelimiter ??= this.textEndDelimiter;
    eol ??= this.eol;
    delimitAllFields ??= this.delimitAllFields;

    if (fieldDelimiter == null || textDelimiter == null) {
      throw new ArgumentError(
          'Field Delimiter ($fieldDelimiter) and Text Delimiter ($textDelimiter) must not be null.');
    }

    if (fieldDelimiter == textDelimiter) {
      throw new ArgumentError(
          'Field Delimiter ($fieldDelimiter) and Text Delimiter ($textDelimiter) must not be equal.');
    }

    var fieldDel = '';

    // Comments assume field and text delimiter are default.
    // [val] _in the comments changes_ depending on the operation after the comment.
    rowValues.fold(sb, (StringBuffer sb, val) {
      // double => 4.2
      String valString = val.toString();

      // 5,3 should become "5,3"

      if (delimitAllFields ||
          _containsAny(valString,
              [fieldDelimiter, textDelimiter, textEndDelimiter, eol])) {
        // ab"cd => ab""cd
        if (_containsAny(valString, [textEndDelimiter])) {
          var newEndDelimiter = "$textEndDelimiter$textEndDelimiter";
          valString = valString.replaceAll(textEndDelimiter, newEndDelimiter);
        }

        sb
          ..write(fieldDel) // ,
          ..write(textDelimiter) // "
          ..write(valString) // 5,3
          ..write(textEndDelimiter); // "
      } else {
        sb..write(fieldDel)..write(valString);
      }
      fieldDel = fieldDelimiter;
      return sb;
    });

    return sb.toString();
  }

  bool _containsAny(String s, List<String> charsToSearchFor) {
    var chars = new Set<int>();
    charsToSearchFor.forEach((word) => chars.addAll(word.codeUnits));
    var it = s.codeUnits.iterator;
    while (it.moveNext()) {
      if (chars.contains(it.current)) return true;
    }
    return false;
  }

  Stream<String> bind(Stream<List> stream) {
    return new Stream<String>.eventTransformed(stream,
        (EventSink sink) => new ComplexConverterStreamEventSink(this, sink));
  }
}

/// The input sink for a chunked list to csv conversion.
///
/// A single row represented by a [List] may be [add]ed an
/// the conversion is added to the output sink.
class List2CsvSink extends ChunkedConversionSink<List<List>> {
  /// The List2CsvConverter which has the configurations (fieldDelimiter,
  /// textDel., eol)
  final ListToCsvConverter _converter;

  /// Rows converted to csv are added to this sink.
  final Sink<String> _outSink;

  List2CsvSink(this._converter, this._outSink);

  @override
  void add(List<List> oneTable) {
    _outSink.add(_converter.convert(oneTable));
  }

  @override
  void close() {
    _outSink.close();
  }
}
