library csv_settings_autodetection;



/// Combines multiple values / settings into one class.
class CsvSettings {
  
  /// If this value is true at least one value wasn't detected.
  /// All fields which haven't been detected are null.
  /// Note however, that a null field could also mean, that the Detected
  /// doesn't care about this field.
  final bool needMoreData;

  /// If this value is null it wasn't detected (only possible if [needMoreDate]
  /// is true or the detector doesn't care about this field.
  final String fieldDelimiter;
  
  /// If this value is null it wasn't detected (only possible if [needMoreDate]
  /// is true or the detector doesn't care about this field.
  final String textDelimiter;
  
  /// If this value is null it wasn't detected (only possible if [needMoreDate]
  /// is true or the detector doesn't care about this field.
  final String textEndDelimiter;
  
  /// If this value is null it wasn't detected (only possible if [needMoreDate]
  /// is true or the detector doesn't care about this field.
  final String eol;
  
  const CsvSettings(this.fieldDelimiter,
                    this.textDelimiter,
                    this.textEndDelimiter,
                    this.eol,
                    this.needMoreData);
}


/// The interface for detection of csv settings.
abstract class CsvSettingsDetector {
  CsvSettings detectFromString(String csv);
  
  CsvSettings detectFromCsvChunks(List<String> csvChunks, bool noMoreChunks) {
    var nullToEmpy = (String chunk) => chunk == null ? '' : chunk;
    return detectFromString(csvChunks.map(nullToEmpy).join());
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
String _findFirst(String csv, List<String> possibleValues) {
  if (csv == null) csv = '';

  if (possibleValues.length == 1) {
    return possibleValues.first;
  }

  var bestMatchIndex = csv.length;
  var bestMatch = null;
  
  possibleValues.forEach((val) {
    if (val == null) return;
  
    final currentIndex = csv.indexOf(val);
  
    if (currentIndex != -1 && currentIndex < bestMatchIndex) {
      bestMatchIndex = currentIndex;
      bestMatch = val;
    }
  
  });
  
  return bestMatch;
}


/// This is a very simple detector, which simple returns the value which has
/// the lowest start position inside the csv.
class FirstOccurenceSettingsDetector extends CsvSettingsDetector {
  
  final List<String> fieldDelimiters;
  final List<String> textDelimiters;
  final List<String> textEndDelimiters;
  final List<String> eols;
  
  const FirstOccurenceSettingsDetector({this.fieldDelimiters,
                                        this.textDelimiters,
                                        this.textEndDelimiters,
                                        this.eols});
  
  @override
  CsvSettings detectFromString(String csv) {
    var needMoreData = false;
    
    var tryValues = (List<String> values) {
      var value;
      if (values != null && values.isNotEmpty) {
        value = _findFirst(csv, values);
        if (value == null) needMoreData = true;
      }
      return value;
    };
    
    String fieldDelimiter = tryValues(fieldDelimiters);
    String textDelimiter = tryValues(textDelimiters);
    String textEndDelimiter = tryValues(textEndDelimiters);
    String eol = tryValues(eols);
    
    return new CsvSettings(fieldDelimiter,
                           textDelimiter,
                           textEndDelimiter,
                           eol,
                           needMoreData);
  }
  
}