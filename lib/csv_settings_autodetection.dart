library csv_settings_autodetection;

/// Combines multiple values / settings into one class.
class CsvSettings {
  /// If this value is true at least one value wasn't detected.
  /// All fields which haven't been detected are null.
  /// Note however, that a null field could also mean, that the Detected
  /// doesn't care about this field.
  final bool? needMoreData;

  /// If this value is null it wasn't detected (only possible if [needMoreDate]
  /// is true or the detector doesn't care about this field.
  final String? fieldDelimiter;

  /// If this value is null it wasn't detected (only possible if [needMoreDate]
  /// is true or the detector doesn't care about this field.
  final String? textDelimiter;

  /// If this value is null it wasn't detected (only possible if [needMoreDate]
  /// is true or the detector doesn't care about this field.
  final String? textEndDelimiter;

  /// If this value is null it wasn't detected (only possible if [needMoreDate]
  /// is true or the detector doesn't care about this field.
  final String? eol;

  const CsvSettings(this.fieldDelimiter, this.textDelimiter,
      this.textEndDelimiter, this.eol, this.needMoreData);
}

/// The interface for detection of csv settings.
abstract class CsvSettingsDetector {
  CsvSettings detectFromString(String csv);

  CsvSettings detectFromCsvChunks(List<String?> csvChunks, bool? noMoreChunks) {
    var nullToEmpty = (String? chunk) => chunk ?? '';
    return detectFromString(csvChunks.map(nullToEmpty).join());
  }

  const CsvSettingsDetector();
}

/// This function goes through every possible value in [possibleValues]
/// and returns the value which has the lowest start position inside
/// [csv]
///
/// If there is only one possible value it returns this value immediately.
///
/// If [csv] is null it becomes ''.
String? _findFirst(String? csv, List<String> possibleValues) {
  csv ??= '';

  if (possibleValues.length == 1) {
    return possibleValues.first;
  }

  var bestMatchIndex = csv.length;
  String? bestMatch;

  possibleValues.forEach((val) {
    final currentIndex = csv!.indexOf(val);

    if (currentIndex != -1 && currentIndex < bestMatchIndex) {
      bestMatchIndex = currentIndex;
      bestMatch = val;
    }
  });

  return bestMatch;
}

/// This is a very simple detector, which simple returns the value which has
/// the lowest start position inside the csv.
class FirstOccurrenceSettingsDetector extends CsvSettingsDetector {
  final List<String>? fieldDelimiters;
  final List<String>? textDelimiters;
  final List<String>? textEndDelimiters;
  final List<String>? eols;

  const FirstOccurrenceSettingsDetector(
      {this.fieldDelimiters,
      this.textDelimiters,
      this.textEndDelimiters,
      this.eols});

  @override
  CsvSettings detectFromString(String csv) {
    var needMoreData = false;

    var tryValues = (List<String>? values) {
      String? value;
      if (values != null && values.isNotEmpty) {
        value = _findFirst(csv, values);
        if (value == null) needMoreData = true;
      }
      return value;
    };

    var fieldDelimiter = tryValues(fieldDelimiters);
    var textDelimiter = tryValues(textDelimiters);
    var textEndDelimiter = tryValues(textEndDelimiters);
    var eol = tryValues(eols);

    return CsvSettings(
        fieldDelimiter, textDelimiter, textEndDelimiter, eol, needMoreData);
  }
}
