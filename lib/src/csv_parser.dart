library csv_parser;

part 'csv_argument_errors.dart';

/// Parses a csv string into a List of rows.  Each row is represented by a
/// List.
///
/// This converter follows the rules of
/// [rfc4180](http://tools.ietf.org/html/rfc4180).
///
/// The default configuration is:
/// * _,_ as field separator
/// * _"_ as text delimiter and
/// * _\r\n_ as eol.
///
///
/// This parser will accept eol and text-delimiters inside unquoted text and
/// not throw an error.
///
/// In addition this converter supports multiple characters for all delimiters
/// and eol.  Also the start text delimiter and end text delimiter may be
/// different.  This means the following text can be parsed:
/// «abc«d»*|*«xy»»z»*|*123
/// And (if configured correctly) will return ['abc«d', 'xy»z', 123]
///
/// Ad rule 3: removed as it is not relevant for this converter.
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

// Notes regarding the implementation:
// The field-separator is called fieldDelimiter (taken from the rfc) the string
// which starts a quoted text is called textDelimiter and the string ending a
// quoted text is called textEndDelimiter.  Example:
//    v-- field separator v-- textEndDelimiter must be doubled
// abc,"long quoted text, "" ← this doesn't stop the quote because there are 2"
//     ^-- textDelimiter                                    textEndDelimiter--^
//
// Note that in this example textDelimiter and textEndDelimiter are the same
// string.
//
// All delimiters  and eol may be multiple characters.
//
// (I will from now on stop mentioning eol matching, which is similar to
//  delimiter matching).
//
// We have a counter for every delimiter.  Before adding a character _c_ to the
// StringBuffer which represents the current field, we find out if _c_ is part
// a delimiter.
// Assume all counters are 0 (the start condition).  If any delimiter starts
// with _c_ we increment the corresponding counter:
// if (delim[delimCounter] == _c_) delimCounter++;
// We do this for every delimiter which is allowed.  Inside quoted strings
// only the textEndDelimiter is compared...
// It is however possible, that we have to match eol, fieldDelimiter and
// textDelimiter at the same time.
//
// !! If they all start with the same character all three counters will be
//    incremented !!
//
// If _c_ matches a delimiter we will not add it the the field stringBuffer!
//
// This goes on until a delimiter is completely matched (the counter == the
// delimiter.length) or the character doesn't match any of the delimiters.
// The complete match is easy: all other counters are reset and the delimiter
// is handled.
// If however a character doesn't match a delimiter but previous characters
// incremented at least one counter, we have to *reparse* the previous matched
// characters: all counters are reset, the first of the previous matched
// characters is added to the field stringBuffer and the other characters are
// reparsed.
//
// A difficult example would be:
// * fieldDelimiter:   ...*
// * textDelimiter:    ...#
// * eol:              .*.*
class CsvParser {
  /// The separator between fields.
  final String? fieldDelimiter;

  /// The delimiter which (optionally) starts, or if textEndDelimiter is null
  /// also ends text fields.
  final String? textDelimiter;

  /// The end delimiter for text.  This allows text to be quoted with different
  /// start / end delimiters: Example:  «abc».
  /// If [textEndDelimiter] is null, [textDelimiter] is used instead;
  final String? textEndDelimiter;

  /// The end of line character which is expected after "row".
  ///
  /// The eol is optional for the last row.
  final String? eol;

  /// Whether we try to parse unquoted text to numbers (int and doubles)
  final bool shouldParseNumbers;

  /// If this variable is true, don't throw an exception if the csv or the
  /// arguments ([fieldDelimiter], [textDelimiter], [textEndDelimiter] or
  /// [eol]) are invalid.  Try not to throw an exception even if the output
  /// possibly does not make any sense any longer.
  ///
  /// In addition if the csv is not formatted correctly an exception is thrown
  /// if [allowInvalid] is false.  An example for such an exception is if a
  /// csv string ends with a quoted field but without a [textEndDelimiter].
  final bool allowInvalid;

  // The parsing state variables (Yes there are a lot):

  /// The already parsed characters of the current field.
  late StringBuffer _field;

  /// The string we are currently parsing.
  String? _csvText;

  /// The position inside [_csvText].
  int _currentPos;

  /// Characters we have to reparse, because a multi-character match was
  /// unsuccessful.  This field is null otherwise.
  String? _pushbackBuffer;

  /// Are we inside a text/string (not necessarily quoted).
  late bool _insideString;

  /// Are we inside a quoted text/string ([_insideString] must be true as well
  /// if [_insideQuotedString] is true).
  bool? _insideQuotedString;

  /// Did we just now parse a [textEndDelimiter]?
  bool? _previousWasTextEndDelimiter;

  // Counters for multi-character matching:

  /// Counts how much of [fieldDelimiter] we have seen.
  /// This is only useful for multi-character delimiters.
  int _matchingFieldDelimiter;

  /// Counts how much of [textDelimiter] we have seen.
  /// This is only useful for multi-character delimiters.
  int _matchingTextDelimiter;

  /// Counts how much of [textEndDelimiter] we have seen.
  /// This is only useful for multi-character delimiters.
  int _matchingTextEndDelimiter;

  /// Counts how much of [eol] we have seen.
  /// This is only useful for multi-character eols (which is normal: \r\n).
  int _matchingEol;

  /// Buffer for already matched chars.  This variable is not strictly
  /// necessary, as we could always look at the matching* counters, find a
  /// non 0 counter and take a substring of the corresponding string.
  late StringBuffer _matchedChars;

  /// If [allowInvalid] is true we only use the user supplied value if it isn't null.
  static String? _argValue(
      bool? allowInvalid, String? userValue, String defaultValue,
      {String? userValue2}) {
    if (userValue != null) return userValue;
    if (userValue2 != null) return userValue2;

    if (allowInvalid == null || allowInvalid) return defaultValue;
    return userValue;
  }

  /// The default values are consistent with
  /// [rfc4180](http://tools.ietf.org/html/rfc4180).
  ///
  /// The arguments are only checked if [allowInvalid] is false.
  ///
  /// In [allowInvalid] is false the arguments are checked with
  /// [verifyArgument].
  CsvParser(
      {String? fieldDelimiter = ',',
      String? textDelimiter = '"',
      String? textEndDelimiter,
      String? eol = '\r\n',
      bool? shouldParseNumbers,
      bool? allowInvalid})
      : this.fieldDelimiter = _argValue(allowInvalid, fieldDelimiter, ','),
        this.textDelimiter = _argValue(allowInvalid, textDelimiter, '"'),
        this.textEndDelimiter = _argValue(allowInvalid, textEndDelimiter, '"',
            userValue2: textDelimiter),
        this.eol = _argValue(allowInvalid, eol, '\r\n'),
        this.shouldParseNumbers =
            shouldParseNumbers != null ? shouldParseNumbers : true,
        this.allowInvalid = allowInvalid != null ? allowInvalid : true,
        _matchingFieldDelimiter = 0,
        _matchingTextDelimiter = 0,
        _matchingTextEndDelimiter = 0,
        _matchingEol = 0,
        _currentPos = 0
  {
    _field = new StringBuffer();
    _pushbackBuffer = null;
    _insideString = false;
    _insideQuotedString = false;
    _previousWasTextEndDelimiter = false;
    _matchedChars = new StringBuffer();

    if (!this.allowInvalid) {
      verifySettings(fieldDelimiter, textDelimiter, textEndDelimiter, eol,
          throwError: true);
    }
  }

  /// Adds [c] to the stringBuffer which holds the value for the current field.
  _addTextToField(String? c) {
    _field.write(c);
    _previousWasTextEndDelimiter = false;
    _insideString = true;
    _resetMatcher();
  }

  /// Reparse the [_pushbackBuffer].
  ///
  /// The [_csvText] is temporarely replaced with [_pushbackBuffer] before
  /// calling [_parseField].
  /// Only call this if [_pushbackBuffer] is not null!
  /// It is possible that there is still something in the buffer after
  /// this call, but only when we completed a field.
  ParsingResult _parsePushbackBuffer() {
    final backupCurrentPos = _currentPos;
    final backupCsvText = _csvText;

    final pushback = _pushbackBuffer!;
    _csvText = pushback;
    _currentPos = 0;
    _pushbackBuffer = null;

    final result = _parseField();

    // if the pushback string is not complete consumed
    if (_currentPos < pushback.length) {
      // this is only possible if we encountered a complete field.
      assert(result.stopReason != ParsingStopReason.EndOfString);

      // create new pushback string:
      _pushbackBuffer = pushback.substring(_currentPos);
    }

    _currentPos = backupCurrentPos;
    _csvText = backupCsvText;

    return result;
  }

  /// Tries to match c against any (allowed) delimiter/eol.
  // See the implementation note at the start of this class.
  bool _match(String c, bool matching) {
    final onlyTextEndDelimiterMatches =
        _insideQuotedString! && !_previousWasTextEndDelimiter!;

    // never look for a start text delimiter inside a quoted string.
    // (even if _previousWasTextEndDelimiter)
    final matchTextDelimiters =
        !_insideQuotedString! && (!matching || _matchingTextDelimiter > 0);

    final matchTextEndDelimiters =
        _insideQuotedString! && (!matching || _matchingTextEndDelimiter > 0);

    final matchFieldDelimiters = !onlyTextEndDelimiterMatches &&
        (!matching || _matchingFieldDelimiter > 0);

    final matchEols =
        !onlyTextEndDelimiterMatches && (!matching || _matchingEol > 0);

    var foundMatch = false;

    // try to match (or finish matching) our "special" strings.

    if (matchTextDelimiters && c == textDelimiter![_matchingTextDelimiter]) {
      _matchingTextDelimiter++;
      foundMatch = true;
    } else {
      _matchingTextDelimiter = 0;
    }

    if (matchTextEndDelimiters &&
        c == textEndDelimiter![_matchingTextEndDelimiter]) {
      _matchingTextEndDelimiter++;
      foundMatch = true;
    } else {
      _matchingTextEndDelimiter = 0;
    }

    if (matchEols && c == eol![_matchingEol]) {
      _matchingEol++;
      foundMatch = true;
    } else {
      _matchingEol = 0;
    }

    if (matchFieldDelimiters && c == fieldDelimiter![_matchingFieldDelimiter]) {
      _matchingFieldDelimiter++;
      foundMatch = true;
    } else {
      _matchingFieldDelimiter = 0;
    }

    if (foundMatch) _matchedChars.write(c);

    return foundMatch;
  }

  /// Resets match counters and clear [_matchedChars] StringBuffer.
  void _resetMatcher() {
    // reset all matcher
    _matchingTextDelimiter = 0;
    _matchingTextEndDelimiter = 0;
    _matchingFieldDelimiter = 0;
    _matchingEol = 0;
    _matchedChars.clear();
  }

  /// Reparses wrongly matched characters.  This is only possible if any
  /// delimiter / eol is multi characters long.
  // Sets the [_pushbackBuffer] and calls [_parseField] which will then
  // call [_parsePushbackBuffer].
  ParsingResult _reparseWronglyMatched() {
    // need to reparse already matched characters

    final matchedCharsText = _matchedChars.toString();

    String firstChar = matchedCharsText[0];

    _addTextToField(firstChar);

    // restart matching with the second char
    _pushbackBuffer = matchedCharsText.substring(1);

    final result = _parseField();

    return result;
  }

  /// Consumes and sets the correct flags after a [textDelimiter] has been
  /// found.
  _consumeTextDelimiter() {
    _resetMatcher();

    // If we are not yet inside a string, we are now
    if (!_insideString) {
      _insideString = true;
      _insideQuotedString = true;
    }
  }

  /// Consumes and sets the correct flags after a [textEndDelimiter] has been
  /// found.
  _consumeTextEndDelimiter() {
    _resetMatcher();

    // We must be inside a quoted string, otherwise textEndDelimiter isn't
    // even considered.

    if (_previousWasTextEndDelimiter!) {
      // we have just read a textEndDelimiter
      // so this is the second textEndDelimiter → output textDelimiter
      _addTextToField(textEndDelimiter);
    } else {
      // for now remember that we have read a textEndDelimiter
      _previousWasTextEndDelimiter = true;
    }
  }

  /// Consumes and sets the correct flags after an [eol] has been found.
  ParsingResult _consumeEol() {
    _resetMatcher();

    assert(_insideQuotedString == false || _previousWasTextEndDelimiter!);

    _insideString = false;
    _insideQuotedString = false;

    bool? quoted = _previousWasTextEndDelimiter;
    _previousWasTextEndDelimiter = false;

    return new ParsingResult(ParsingStopReason.Eol, quoted);
  }

  /// Consumes and sets the correct flags after a [fieldDelimiter] has been
  /// found.
  ParsingResult _consumeFieldDelimiter() {
    _resetMatcher();

    _insideString = false;
    assert(_insideQuotedString == false || _previousWasTextEndDelimiter!);
    _insideQuotedString = false;

    bool? quoted = _previousWasTextEndDelimiter;
    _previousWasTextEndDelimiter = false;

    return new ParsingResult(ParsingStopReason.FieldDelimiter, quoted);
  }

  /// Looks at matching counters to find out if we are currently in a
  /// matching state.  In 'matching' state some characters are not yet added
  /// to the field StringBuffer because they could be part of a delimiter or
  /// eol.
  bool _matching() {
    // we are in matching "state" if at least one counter is > 0
    return _matchingEol > 0 ||
        _matchingFieldDelimiter > 0 ||
        _matchingTextDelimiter > 0 ||
        _matchingTextEndDelimiter > 0;
  }

  /// Goes through [_csvText] until either no more characters are left, or
  /// until either a complete field has been parsed because we encountered an
  /// unquoted [eol] or we encountered an unquoted [fieldDelimiter].
  ParsingResult _parseField() {
    if (_pushbackBuffer != null) {
      final result = _parsePushbackBuffer();
      if (result.stopReason != ParsingStopReason.EndOfString) return result;
    }

    while (_currentPos < _csvText!.length) {
      final c = _csvText![_currentPos];

      _currentPos++;

      // we are in matching "state" if at least one counter is > 0
      final matching = _matching();

      final foundMatch = _match(c, matching);

      if (matching && !foundMatch) {
        // retry the current character later
        _currentPos--;

        final result = _reparseWronglyMatched();
        if (result.stopReason != ParsingStopReason.EndOfString) return result;
        continue;
      }

      if (!foundMatch) {
        _addTextToField(c);
        continue;
      }

      // otherwise treat complete matches
      bool matchedTextDelimiter =
          _matchingTextDelimiter == textDelimiter!.length;
      if (matchedTextDelimiter) _consumeTextDelimiter();

      // IMPORTANT: try to match a complete textEndDelimiter only _AFTER_
      // trying to match a complete textDelimiter!  They usually are the same!
      bool matchedTextEndDelimiter =
          _matchingTextEndDelimiter == textEndDelimiter!.length;
      if (matchedTextEndDelimiter) _consumeTextEndDelimiter();

      bool matchedEol = _matchingEol == eol!.length;
      if (matchedEol) return _consumeEol();

      bool matchedFieldDelimiter =
          _matchingFieldDelimiter == fieldDelimiter!.length;
      if (matchedFieldDelimiter) return _consumeFieldDelimiter();
    }

    return new ParsingResult(
        ParsingStopReason.EndOfString, _previousWasTextEndDelimiter);
  }

  /// Adds [value] to [row].  Unless value was [quoted] or [_shouldParseNumbers]
  /// is false tries to convert value to a number.  (If possible int, otherwise
  /// double).
  void _addValueToRow(String value, List row, bool? quoted) {
    if (!shouldParseNumbers || quoted!)
      row.add(value);
    else {
      row.add(num.tryParse(value) ?? value);
    }
  }

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
    final errors = <ArgumentError>[];
    if (fieldDelimiter == null) errors.add(new FieldDelimiterNullError());
    if (textDelimiter == null) errors.add(new TextDelimiterNullError());
    if (textEndDelimiter == null) errors.add(new TextEndDelimiterNullError());
    if (eol == null) errors.add(new EolNullError());
    throwError ??= false;

    final argumentMap = {
      'fieldDelimiter': fieldDelimiter,
      'textDelimiter': textDelimiter,
      'textEndDelimiter': textEndDelimiter,
      'eol': eol
    };

    // n² !
    argumentMap.forEach((String name, String? value) {
      argumentMap.forEach((String name2, String? value2) {
        if (name == 'textDelimiter' && name2 == 'textEndDelimiter' ||
            name == 'textEndDelimiter' && name2 == 'textDelimiter') return;

        // Don't compare settings twice
        if (name.compareTo(name2) >= 0) return;
        if (value == null || value2 == null) return;

        bool valuesAreEqual = value == value2;

        if (valuesAreEqual ||
            !valuesAreEqual && value.startsWith(value2) ||
            !valuesAreEqual && value2.startsWith(value)) {
          errors.add(new SettingsValuesEqualError(name, value, name2, value2));
        }
      });
    });

    if (throwError && errors.isNotEmpty) {
      if (errors.length == 1) throw errors.first;
      throw new ArgumentError(errors.map((e) => e.toString()).join('\n'));
    }
    return errors;
  }

  /// Parses [csv] and appends fields to [currentRow] until either an unquoted
  /// [eol] has been parsed or no more characters are left.
  ///
  /// If [fieldCompleteWhenEndOfString] and no more characters are left the
  /// unfinished match characters are added to the row as well.
  ///
  /// If [continueCsv] is true [csv] is ignored and this parser continues with
  /// the values from a previous call to this function.
  ///
  /// If there was no previous call [csv] is still used!
  ParsingResult convertRow(String? csv, List currentRow,
      {bool? continueCsv, bool? fieldCompleteWhenEndOfString}) {
    continueCsv ??= false;
    fieldCompleteWhenEndOfString ??= true;

    if (!continueCsv || _csvText == null) {
      _csvText = csv == null ? '' : csv;
      _currentPos = 0;
    }

    ParsingResult result;
    for (;;) {
      result = _parseField();
      var stopReason = result.stopReason;

      if (!fieldCompleteWhenEndOfString &&
          stopReason == ParsingStopReason.EndOfString) break;

      // If end of string means that the field is complete, we have to reparse
      // the already matched characters.
      while (fieldCompleteWhenEndOfString &&
          stopReason == ParsingStopReason.EndOfString &&
          _matching()) {
        result = _reparseWronglyMatched();
        stopReason = result.stopReason;
      }

      var value = _field.toString();
      _field.clear();

      var isOptionalEolAtEnd = stopReason == ParsingStopReason.EndOfString &&
          !result.quoted! &&
          value.isEmpty &&
          currentRow.isEmpty;

      if (isOptionalEolAtEnd) break;

      _addValueToRow(value, currentRow, result.quoted);

      if (stopReason == ParsingStopReason.Eol) break;
      if (stopReason == ParsingStopReason.EndOfString) break;
    }

    if (!allowInvalid &&
        result.stopReason == ParsingStopReason.EndOfString &&
        fieldCompleteWhenEndOfString &&
        _insideQuotedString!) {
      throw new InvalidCsvException(textEndDelimiter);
    }
    return result;
  }

  /// Parses the [csv] and returns a List (rows) of Lists (columns).
  List<List> convert(String? csv) {
    var rows = <List>[];

    for (;;) {
      final currentRow = [];

      final result = convertRow(csv, currentRow, continueCsv: true);

      if (currentRow.isNotEmpty) {
        rows.add(currentRow);
      } else
        assert(result.stopReason == ParsingStopReason.EndOfString);

      if (result.stopReason == ParsingStopReason.EndOfString) break;
    }

    return rows;
  }
}

// Currently only used when csv ends with a quoted field without the end quote.
// If we find start throwing this exception for other "errors".  We have to
// move the error message to another place.
/// The Csv ist not RFC conform.
class InvalidCsvException extends FormatException {
  const InvalidCsvException(String? textEndDelimiter)
      : super('The text end delimiter ($textEndDelimiter) for the last field '
            'is missing.');
}

/// The possible reason why parsing a field stopped.
class ParsingStopReason {
  final String _value;

  const ParsingStopReason._(this._value);
  toString() => '$_value';

  static const Eol = const ParsingStopReason._('Eol');
  static const FieldDelimiter = const ParsingStopReason._('FieldDelimiter');
  static const EndOfString = const ParsingStopReason._('EndOfString');
}

/// Information after the parsing of a field has stopped.
class ParsingResult {
  /// The reason for the stop.
  final ParsingStopReason stopReason;

  /// Was the previous field quoted.  This information prevents quoted numbers
  /// to be converted to ints/doubles.
  final bool? quoted;

  ParsingResult(this.stopReason, this.quoted);
}
