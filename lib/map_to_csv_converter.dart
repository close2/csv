part of csv;

enum ExtrasActions { raise, ignore }

/// Converts rows -- a [List] of [Map]s into a csv String.
///
/// Usage:
///   var sb = new StringBuffer();
///
///   var writer = MapToCsvConverter(sb, field_names);
///   writer.writeheader();
///   writer.writerows(data_list);
///
///   print(f.toString());
///
class MapToCsvConverter {
  StringBuffer sb;
  List<String> fieldNames;
  ExtrasActions extrasAction;

  ListToCsvConverter _listConverter;

  /// This relies on [ListToCsvConverter] to do the actual converting.
  ///
  /// Required arguments:
  ///
  /// [sb] is [StringBuffer] to write results to
  /// [fieldNames] is a list of [Map] keys in the desired output order
  ///
  /// Optional arguments:
  ///
  /// [extrasAction] determines whether or not it is ok for the data
  /// to have fields not present in [fieldNames]. Will raise an exception
  /// by default.
  ///
  /// Can also receive any arguments that [ListToCsvConverter] takes.
  ///
  MapToCsvConverter(
    this.sb,
    this.fieldNames, {
    this.extrasAction: ExtrasActions.raise,
    String fieldDelimiter: defaultFieldDelimiter,
    String textDelimiter: defaultTextDelimiter,
    String textEndDelimiter,
    String eol: defaultEol,
    bool delimitAllFields: defaultDelimitAllFields,
  }) {
    _listConverter = new ListToCsvConverter(
      fieldDelimiter: fieldDelimiter,
      textDelimiter: textDelimiter,
      textEndDelimiter: textEndDelimiter,
      eol: eol,
      delimitAllFields: delimitAllFields,
    );
  }

  void writerow(Map rowdict) {
    _listConverter.convertSingleRow(sb, _mapToList(rowdict));
    sb.write(_listConverter.eol);
  }

  void writerows(List<Map> rowdicts) {
    rowdicts.forEach((row_dict) {
      writerow(row_dict);
    });
  }

  void writeheader() {
    var header_map = new Map.fromIterable(fieldNames,
        key: (field) => field, value: (field) => field);
    writerow(header_map);
  }

  List<String> _mapToList(Map rowdict) {
    if (extrasAction == ExtrasActions.raise) {
      var extraFields = _findExtraFields(rowdict);
      if (extraFields.length > 0) {
        throw new Exception(
            'Map contains fields not in fieldNames: "${extraFields.join(",")}"');
      }
    }

    return fieldNames.map((field) => rowdict[field]).toList();
  }

  List<String> _findExtraFields(Map data) =>
      data.keys.toList()..removeWhere((e) => fieldNames.contains(e));
}
