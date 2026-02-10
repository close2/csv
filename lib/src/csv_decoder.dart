import 'dart:convert';
import 'csv_row.dart';

/// A converter that converts a CSV string into a [List<List<dynamic>>].
class CsvDecoder extends Converter<String, List<List<dynamic>>> {
  /// The separator between fields. If null, it will be auto-detected.
  final String? fieldDelimiter;

  /// The character used for quoting fields.
  final String quoteCharacter;

  /// The character used for escaping characters inside quoted fields.
  /// If null, it defaults to the [quoteCharacter].
  final String? escapeCharacter;

  /// Whether to skip empty lines.
  final bool skipEmptyLines;

  /// A function that can be used to transform each field after decoding.
  final dynamic Function(dynamic field, int index, String? header)?
  fieldTransform;

  /// Whether to parse the first row as headers and return [CsvRow]s.
  final bool parseHeaders;

  /// Whether to automatically parse numbers and booleans.
  final bool dynamicTyping;

  /// Creates a [CsvDecoder].
  ///
  /// [fieldDelimiter] can be null for auto-detection.
  /// [quoteCharacter] defaults to '"'.
  /// [skipEmptyLines] defaults to true.
  /// [parseHeaders] defaults to false.
  const CsvDecoder({
    this.fieldDelimiter,
    this.quoteCharacter = '"',
    this.escapeCharacter,
    this.skipEmptyLines = true,
    this.fieldTransform,
    this.parseHeaders = false,
    this.dynamicTyping = false,
  }) : assert(
         quoteCharacter.length == 1,
         'quoteCharacter must be a single character',
       ),
       assert(
         escapeCharacter == null || escapeCharacter.length == 1,
         'escapeCharacter must be a single character',
       );

  @override
  List<List<dynamic>> convert(String input) {
    if (input.isEmpty) return [];

    final output = <List<dynamic>>[];
    final outSink = ChunkedConversionSink<List<List<dynamic>>>.withCallback((
      result,
    ) {
      for (var chunk in result) {
        output.addAll(chunk);
      }
    });
    final sink = startChunkedConversion(outSink);
    sink.add(input);
    sink.close();
    return output;
  }

  @override
  StringConversionSink startChunkedConversion(Sink<List<List<dynamic>>> sink) {
    return _CsvDecoderSink(
      sink,
      fieldDelimiter,
      quoteCharacter,
      escapeCharacter,
      skipEmptyLines,
      fieldTransform,
      parseHeaders,
      dynamicTyping,
    );
  }
}

class _CsvDecoderSink extends StringConversionSink {
  final Sink<List<List<dynamic>>> _outSink;
  final String? _presetDelimiter;
  final String _quoteCharacter;
  final String? _escapeCharacter;
  final bool _skipEmptyLines;
  final dynamic Function(dynamic field, int index, String? header)?
  _fieldTransform;
  final bool _parseHeaders;
  final bool _dynamicTyping;

  String? _delimiter;
  bool _inQuotes = false;
  final _buffer = StringBuffer();
  StringBuffer? _headerBuffer;
  var _currentRow = <dynamic>[];
  bool _isFirstChunk = true;
  Map<String, int>? _headers;
  String? _deferredCharacter;

  _CsvDecoderSink(
    this._outSink,
    this._presetDelimiter,
    this._quoteCharacter,
    this._escapeCharacter,
    this._skipEmptyLines,
    this._fieldTransform,
    this._parseHeaders,
    this._dynamicTyping,
  ) {
    _delimiter = _presetDelimiter;
    if (_delimiter == null) {
      _headerBuffer = StringBuffer();
    }
  }

  int _fieldIndex = 0;
  List<String>? _indexToHeader;

  @override
  void add(String chunk) {
    if (_deferredCharacter != null) {
      chunk = _deferredCharacter! + chunk;
      _deferredCharacter = null;
    }
    _processChunk(chunk, 0, chunk.length, false);
  }

  @override
  void addSlice(String chunk, int start, int end, bool isLast) {
    if (_deferredCharacter != null) {
      // We have to allocate a new string to satisfy the contiguous requirement
      // for the deferred character + new chunk.
      // This is rare (only happens if split exactly after escape).
      var slice = chunk.substring(start, end);
      chunk = _deferredCharacter! + slice;
      _deferredCharacter = null;
      _processChunk(chunk, 0, chunk.length, isLast);
    } else {
      _processChunk(chunk, start, end, isLast);
    }
  }

  void _processChunk(String chunk, int start, int end, bool isLast) {
    if (end - start <= 0) {
      if (isLast) close();
      return;
    }

    if (_isFirstChunk) {
      if (_delimiter == null) {
        _headerBuffer!.write(chunk.substring(start, end));

        final combined = _headerBuffer.toString();

        // Count newlines to see if we have enough lines for detection (10 lines).
        // Also have a fallback byte limit (e.g., 2KB) to avoid buffering too much if lines are huge.
        // And ensure we have at least a few chars or a newline for safety.
        int newlineCount = 0;
        for (int j = 0; j < combined.length; j++) {
          if (combined.codeUnitAt(j) == 10) newlineCount++;
        }

        bool hasEnoughData = newlineCount >= 10 || combined.length >= 2048;
        // Minimum safety check for "sep=" or BOM
        bool hasMinimumData =
            combined.length >= 32 ||
            combined.contains('\n') ||
            combined.contains('\r');

        if (!isLast && (!hasMinimumData || !hasEnoughData)) {
          return;
        }

        final bufStart = _checkBOMAndSep(combined);
        _delimiter ??= _detectDelimiter(combined.substring(bufStart));

        // Use the combined buffer as the chunk to process
        chunk = combined;
        start = bufStart;
        end = chunk.length;
        // _headerBuffer is no longer needed
        _headerBuffer = null;
      } else {
        // Even if delimiter is known, we must check for BOM.
        if (chunk.startsWith('\ufeff', start)) {
          start += 1;
        }
      }
      _isFirstChunk = false;
    }

    if (!isLast && end > start) {
      final actualEscapeChar = _escapeCharacter ?? _quoteCharacter;
      final escapeCode = actualEscapeChar.codeUnitAt(0);

      var trailingEscapes = 0;
      // Check trailing characters, but stop if we hit start
      for (var i = end - 1; i >= start; i--) {
        if (chunk.codeUnitAt(i) == escapeCode) {
          trailingEscapes++;
        } else {
          break;
        }
      }

      if (trailingEscapes % 2 == 1) {
        _deferredCharacter = actualEscapeChar;
        end--;
      }
    }

    // Check for partial multi-char delimiter at the end (Normal State only)
    if (!isLast &&
        !_inQuotes &&
        _delimiter != null &&
        _delimiter!.length > 1 &&
        end > start) {
      final delim = _delimiter!;
      // We only care about suffixes shorter than the delimiter.
      // E.g. delim "::", chunk ends with ":".
      var limit = delim.length - 1;
      if (limit > end - start) limit = end - start;

      for (var len = limit; len > 0; len--) {
        // Check if chunk suffix of length 'len' matches delim prefix
        var match = true;
        for (var j = 0; j < len; j++) {
          if (chunk.codeUnitAt(end - len + j) != delim.codeUnitAt(j)) {
            match = false;
            break;
          }
        }
        if (match) {
          _deferredCharacter = chunk.substring(end - len, end);
          end -= len;
          break;
        }
      }
    }

    // Check for split CRLF (Normal State only)
    // If chunk ends with \r, defer it to check if next chunk starts with \n
    if (_deferredCharacter == null &&
        !isLast &&
        !_inQuotes &&
        end > start &&
        chunk.codeUnitAt(end - 1) == 13) {
      _deferredCharacter = '\r';
      end--;
    }

    if (end <= start) return;

    final results = <List<dynamic>>[];
    final actualEscapeChar = _escapeCharacter ?? _quoteCharacter;
    final delim = _delimiter!;

    // We use code units for much faster indexing than String[i].
    final int quoteCode = _quoteCharacter.codeUnitAt(0);
    final int escapeCode = actualEscapeChar.codeUnitAt(0);
    final int? delimCode = delim.length == 1 ? delim.codeUnitAt(0) : null;
    final int nlCode = 10; // \n
    final int crCode = 13; // \r

    int i = start;
    // anchor points to the start of the current "unprocessed" block of text.
    int anchor = start;

    while (i < end) {
      final charCode = chunk.codeUnitAt(i);

      if (_inQuotes) {
        // --- QUOTED STATE ---
        if (charCode == escapeCode &&
            i + 1 < end &&
            chunk.codeUnitAt(i + 1) == quoteCode) {
          // Handle escaped quote (e.g., "" or \")
          if (i > anchor) _buffer.write(chunk.substring(anchor, i));
          _buffer.write(_quoteCharacter);
          i++;
          anchor = i + 1;
        } else if (charCode == quoteCode) {
          // Check if this is truly the end of the quoted field.
          // A closing quote must be followed by a delimiter, a newline, or EOF.
          var isClosingQuote = false;
          if (i + 1 == end) {
            isClosingQuote = true;
          } else {
            // Fast path for single-character delimiters
            if (delimCode != null) {
              final nextCode = chunk.codeUnitAt(i + 1);
              if (nextCode == delimCode ||
                  nextCode == nlCode ||
                  nextCode == crCode) {
                isClosingQuote = true;
              }
            } else {
              // Check for partial delimiter match at the end of the chunk
              if (!isLast &&
                  i + 1 < end &&
                  delimCode == null &&
                  delim.length > 1) {
                // Check if the remaining suffix is a prefix of the delimiter
                // remaining suffix is chunk[i+1...end]
                int suffixLen = end - (i + 1);
                if (suffixLen < delim.length) {
                  var match = true;
                  for (var j = 0; j < suffixLen; j++) {
                    if (chunk.codeUnitAt(i + 1 + j) != delim.codeUnitAt(j)) {
                      match = false;
                      break;
                    }
                  }
                  if (match) {
                    // Partial match found! Defer the whole thing from 'i'.
                    // i is the quote.
                    _deferredCharacter = chunk.substring(i, end);
                    end = i;
                    // Break the loop by setting i = end?
                    // The loop condition is i < end.
                    // We just reduced end.
                    break;
                  }
                }
              }

              if (chunk.startsWith(delim, i + 1) ||
                  chunk.startsWith('\n', i + 1) ||
                  chunk.startsWith('\r', i + 1)) {
                isClosingQuote = true;
              }
            }
          }

          if (isClosingQuote) {
            if (i > anchor) _buffer.write(chunk.substring(anchor, i));
            _inQuotes = false;
            anchor = i + 1;
          }
        }
      } else {
        // --- NORMAL STATE ---
        if (charCode == quoteCode && _buffer.isEmpty && i == anchor) {
          // Start of a quoted field.
          _inQuotes = true;
          anchor = i + 1;
        } else if (delimCode != null
            ? charCode == delimCode
            : chunk.startsWith(delim, i)) {
          // End of a field.
          if (i > anchor) _buffer.write(chunk.substring(anchor, i));
          _currentRow.add(_transform(_buffer.toString()));
          _fieldIndex++;
          _buffer.clear();
          if (delimCode == null) i += delim.length - 1;
          anchor = i + 1;
        } else if (charCode == crCode || charCode == nlCode) {
          // Handle \r or \r\n line endings.
          if (i > anchor) _buffer.write(chunk.substring(anchor, i));
          _currentRow.add(_transform(_buffer.toString()));
          _fieldIndex++;
          _buffer.clear();
          _finalizeRow(results);
          if (i + 1 < end &&
              charCode == crCode &&
              chunk.codeUnitAt(i + 1) == nlCode) {
            i++;
          }
          anchor = i + 1;
        }
      }
      i++;
    }

    // Capture any remaining text in the chunk.
    if (anchor < end) {
      _buffer.write(chunk.substring(anchor, end));
    }

    if (results.isNotEmpty) {
      _outSink.add(results);
    }

    if (isLast) close();
  }

  /// Checks for a Byte Order Mark (BOM) or an Excel-style `sep=` delimiter hint.
  ///
  /// Returns the index where the actual CSV data starts.
  int _checkBOMAndSep(String chunk) {
    var offset = 0;
    // Check for UTF-8 BOM
    if (chunk.startsWith('\ufeff')) {
      offset = 1;
    }

    final head = chunk.substring(offset);
    // Check for "sep=;" style delimiter hint often used by Excel.
    if (head.startsWith('sep=')) {
      final newlineIndex = head.indexOf(RegExp(r'\r\n|\r|\n'));
      if (newlineIndex != -1) {
        final sepLine = head.substring(0, newlineIndex);
        final potentialSep = sepLine.substring(4).trim();
        if (potentialSep.isNotEmpty) {
          _delimiter = potentialSep;
          offset += newlineIndex;
          // Skip the newline as well
          if (head.substring(newlineIndex).startsWith('\r\n')) {
            offset += 2;
          } else {
            offset += 1;
          }
        }
      }
    }
    return offset;
  }

  /// Finalizes the current row, adds it to [results], and clears `_currentRow`.
  /// Handles header parsing and [CsvRow] conversion if enabled.
  void _finalizeRow(List<List<dynamic>> results) {
    if (!_skipEmptyLines || _currentRow.any((e) => e != '')) {
      if (_parseHeaders && _headers == null) {
        // First row is the header row.
        _headers = {
          for (var i = 0; i < _currentRow.length; i++)
            _currentRow[i].toString(): i,
        };
        _indexToHeader = _currentRow.map((e) => e.toString()).toList();
      } else {
        final rowToAdd = _headers != null
            ? CsvRow(_currentRow, _headers!)
            : _currentRow;
        results.add(rowToAdd);
      }
    }
    _currentRow = [];
    _fieldIndex = 0;
  }

  dynamic _transform(String field) {
    dynamic value = field;
    if (_dynamicTyping) {
      if (field == 'true') {
        value = true;
      } else if (field == 'false') {
        value = false;
      } else {
        // Try parsing numbers
        final asInt = int.tryParse(field);
        if (asInt != null) {
          value = asInt;
        } else {
          final asDouble = double.tryParse(field);
          if (asDouble != null) {
            value = asDouble;
          }
        }
      }
    }

    final transform = _fieldTransform;
    if (transform == null) return value;

    // Safely gets the header or null if index is out of bounds or list is null
    final header = _indexToHeader?.elementAtOrNull(_fieldIndex);

    return transform(value, _fieldIndex, header);
  }

  @override
  void close() {
    if (_isFirstChunk && _headerBuffer != null && _headerBuffer!.isNotEmpty) {
      final combined = _headerBuffer.toString();
      final start = _checkBOMAndSep(combined);
      _delimiter ??= _detectDelimiter(combined.substring(start));
      _isFirstChunk = false;
      _headerBuffer = null;
      _processChunk(
        combined.substring(start),
        0,
        combined.length - start,
        true,
      );
      return;
    }

    if (!_isFirstChunk || _buffer.isNotEmpty || _currentRow.isNotEmpty) {
      if (_currentRow.isNotEmpty || _buffer.isNotEmpty) {
        _currentRow.add(_transform(_buffer.toString()));
        _fieldIndex++;
        final results = <List<dynamic>>[];
        _finalizeRow(results);
        if (results.isNotEmpty) {
          _outSink.add(results);
        }
        _buffer.clear();
      }
    }
    _outSink.close();
  }

  /// Automatically detects the delimiter by analyzing the first few lines of the input.
  ///
  /// It scores possible delimiters based on:
  /// 1. Frequency: Total number of occurrences.
  /// 2. Consistency: Bonus points if lines have the same number of delimiters.
  String _detectDelimiter(String input) {
    if (input.isEmpty) return ',';
    final possibleDelimiters = [',', ';', '\t', '|'];
    String? bestDelimiter;
    var maxScore = -1;
    final lines = input.split(RegExp(r'\r\n|\r|\n'));
    for (final delimiter in possibleDelimiters) {
      if (!input.contains(delimiter)) continue;
      var totalFields = 0;
      var lastFieldCount = -1;
      var consistencyBonus = 0;
      // We only look at the first 10 lines for performance.
      for (var j = 0; j < (lines.length > 10 ? 10 : lines.length); j++) {
        final line = lines[j];
        if (line.isEmpty) continue;
        final count = delimiter.allMatches(line).length;
        if (count > 0) {
          totalFields += count;
          // Consistency bonus: If lines have the same number of delimiters,
          // it's highly likely to be the correct one.
          if (lastFieldCount != -1 && count == lastFieldCount) {
            consistencyBonus += 2;
          }
          lastFieldCount = count;
        }
      }
      final score = totalFields + consistencyBonus;
      if (score > maxScore) {
        maxScore = score;
        bestDelimiter = delimiter;
      }
    }
    return bestDelimiter ?? ',';
  }
}
