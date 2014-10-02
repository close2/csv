library csv_to_list_test;


import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:csv/csv.dart';
import 'package:csv/src/csv_parser.dart';

import 'test_data.dart';

part 'csv_to_list_transformer_test.dart';
part 'csv_to_list_converter_test.dart';



final commaDoubleQuotCsvToListConverter =
    new CsvToListConverter(parseNumbers: false);
final commaDoubleQuotCsvToListConverterParseNumbers =
    new CsvToListConverter();
final semicolonDoubleQuotCsvToListConverter =
    new CsvToListConverter(fieldDelimiters: ';',
                           parseNumbers: false);
final dotDoubleQuotCsvToListConverter =
    new CsvToListConverter(fieldDelimiters: '.',
                           parseNumbers: false);
final dotSingleQuotCsvToListConverterUnixEol =
    new CsvToListConverter(fieldDelimiters: '.',
                           textDelimiters: "'",
                           eols: '\n',
                           parseNumbers: false);
final dotSingleQuotCsvToListConverterUnixEol_double =
    new CsvToListConverter(fieldDelimiters: '.',
                           textDelimiters: "'",
                           textEndDelimiters: '"',
                           eols: '\n',
                           parseNumbers: false);
final aaBbCsvToListConverter =
    new CsvToListConverter(fieldDelimiters: 'aa',
                           textDelimiters: 'bb',
                           parseNumbers: false);
final complexConverter =
    new CsvToListConverter(fieldDelimiters: '...*',
                           textDelimiters: '...#',
                           eols: '....',
                           parseNumbers: true);
final complex2Converter =
    new CsvToListConverter(fieldDelimiters: '...*',
                           textDelimiters: '...#',
                           eols: '.*.*',
                           parseNumbers: true);
final complex3Converter =
    new CsvToListConverter(fieldDelimiters: ',',
                           textDelimiters: '.,a,b,__',
                           eols: '_xyz',
                           parseNumbers: true);


main() {

  main_converter();

  main_transformer();


  test('Argument verification works', () {
    final parser = new CsvParser();
    expect(parser.verifyCurrentSettings(), equals([]));

    var errors = parser.verifySettings('a',
                                       'a',
                                       'b',
                                       '\r\n',
                                       throwError: false);
    expect(errors.length, equals(1));
    expect(errors.first.runtimeType, equals(SettingsValuesEqualError));

    errors = parser.verifySettings('a', null, 'b', '\r\n', throwError: false);
    expect(errors.length, equals(1));
    expect(errors.first.runtimeType, equals(TextDelimiterNullError));

    errors = parser.verifySettings(null, 'a', null, 'a', throwError: false);
    expect(errors.length, equals(3));
    expect(errors.map((e) => e.runtimeType),
           contains(FieldDelimiterNullError));
    expect(errors.map((e) => e.runtimeType),
           contains(TextEndDelimiterNullError));
    expect(errors.map((e) => e.runtimeType),
           contains(SettingsValuesEqualError));
  });

}