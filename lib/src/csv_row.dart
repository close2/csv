import 'dart:collection';

/// A wrapper around a CSV row that allows access by header name or index.
class CsvRow extends ListBase<dynamic> {
  final List<dynamic> _fields;
  final Map<String, int> _headerMap;

  /// Creates a [CsvRow] from a list of fields and a header map.
  CsvRow(this._fields, this._headerMap);

  @override
  int get length => _fields.length;

  @override
  set length(int newLength) => _fields.length = newLength;

  @override
  dynamic operator [](Object key) {
    if (key is int) {
      // Access by column index.
      return _fields[key];
    } else if (key is String) {
      // Access by header name.
      final index = _headerMap[key];
      if (index != null && index < _fields.length) {
        return _fields[index];
      }
    }
    return null;
  }

  @override
  void operator []=(int index, dynamic value) {
    _fields[index] = value;
  }

  /// Returns a map representation of this row.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    _headerMap.forEach((key, index) {
      if (index < _fields.length) {
        map[key] = _fields[index];
      }
    });
    return map;
  }

  /// Returns the header map.
  Map<String, int> get headerMap => _headerMap;

  /// Returns the header name for a given column index.
  String? getHeaderName(int index) {
    for (final entry in _headerMap.entries) {
      if (entry.value == index) return entry.key;
    }
    return null;
  }
}
