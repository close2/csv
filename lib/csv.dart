library csv;

import 'dart:async';
import 'dart:convert';

import 'csv_settings_autodetection.dart';
import 'src/complex_converter.dart';
import 'src/csv_parser.dart';

part 'csv_to_list_converter.dart';
part 'list_to_csv_converter.dart';
part 'map_to_csv_converter.dart';

enum EmptyValue { NULL }

/// The RFC conform default value for field delimiter.
const String defaultFieldDelimiter = ',';

/// The RFC conform default value for the text delimiter.
const String defaultTextDelimiter = '"';

/// The RFC conform default value for eol.
const String defaultEol = '\r\n';

const bool defaultDelimitAllFields = false;

/// See [CsvToListConverter] and [ListToCsvConverter].
class CsvCodec {
  final CsvToListConverter decoder;

  final ListToCsvConverter encoder;

  CsvCodec(
      {String fieldDelimiter = defaultFieldDelimiter,
      String textDelimiter = defaultTextDelimiter,
      String? textEndDelimiter,
      String eol = defaultEol,
      bool shouldParseNumbers = true,
      bool allowInvalid = true,
      bool delimitAllFields = defaultDelimitAllFields,
      convertNullTo,
      convertEmptyTo})
      : decoder = CsvToListConverter(
            fieldDelimiter: fieldDelimiter,
            textDelimiter: textDelimiter,
            textEndDelimiter: textEndDelimiter,
            eol: eol,
            shouldParseNumbers: shouldParseNumbers,
            allowInvalid: allowInvalid,
            convertEmptyTo: convertEmptyTo),
        encoder = ListToCsvConverter(
            fieldDelimiter: fieldDelimiter,
            textDelimiter: textDelimiter,
            textEndDelimiter: textEndDelimiter,
            eol: eol,
            delimitAllFields: delimitAllFields,
            convertNullTo: convertNullTo);
}
