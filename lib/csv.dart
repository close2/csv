library csv;

import 'dart:convert';
import 'dart:async';

import 'src/csv_parser.dart';

part 'csv_to_list_converter.dart';
part 'list_to_csv_converter.dart';


/// This is the RFC conform default value for field delimiter.
const String defaultFieldDelimiter = ',';

/// This is the RFC conform default value for the text delimiter.
const String defaultTextDelimiter = '"';

/// This is the RFC conform default value for eol.
const String defaultEol = '\r\n';


/// A codec which converts a csv string ↔ List of rows.
///
/// See [CsvToListConverter] and [ListToCsvConverter].
class CsvCodec extends Codec<String, List> {

  final CsvToListConverter encoder;

  final ListToCsvConverter decoder;


  CsvCodec({String fieldDelimiter: defaultFieldDelimiter,
            String textDelimiter: defaultTextDelimiter,
            String textEndDelimiter,
            String eol: defaultEol,
            bool parseNumbers: true,
            bool allowInvalid: true})
      : encoder = new CsvToListConverter(fieldDelimiters: fieldDelimiter,
                                         textDelimiters: textDelimiter,
                                         textEndDelimiters: textEndDelimiter,
                                         eols: eol,
                                         parseNumbers: parseNumbers,
                                         allowInvalid: allowInvalid),
        decoder = new ListToCsvConverter(fieldDelimiter: fieldDelimiter,
                                         textDelimiter: textDelimiter,
                                         textEndDelimiter: textEndDelimiter,
                                         eol: eol);

}


