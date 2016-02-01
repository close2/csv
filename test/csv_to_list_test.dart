library csv_to_list_test;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:csv/csv.dart';
import 'package:csv/src/csv_parser.dart';
import 'package:csv/csv_settings_autodetection.dart';

import 'test_data.dart';

part 'csv_to_list_transformer_test.dart';
part 'csv_to_list_converter_test.dart';

final commaDoubleQuotCsvToListConverter =
    new CsvToListConverter(shouldParseNumbers: false);
final commaDoubleQuotCsvToListConverterParseNumbers = new CsvToListConverter();
final semicolonDoubleQuotCsvToListConverter =
    new CsvToListConverter(fieldDelimiter: ';', shouldParseNumbers: false);
final dotDoubleQuotCsvToListConverter =
    new CsvToListConverter(fieldDelimiter: '.', shouldParseNumbers: false);
final dotSingleQuotCsvToListConverterUnixEol = new CsvToListConverter(
    fieldDelimiter: '.',
    textDelimiter: "'",
    eol: '\n',
    shouldParseNumbers: false);
final dotSingleQuotCsvToListConverterUnixEol_double = new CsvToListConverter(
    fieldDelimiter: '.',
    textDelimiter: "'",
    textEndDelimiter: '"',
    eol: '\n',
    shouldParseNumbers: false);
final aaBbCsvToListConverter = new CsvToListConverter(
    fieldDelimiter: 'aa', textDelimiter: 'bb', shouldParseNumbers: false);
final complexConverter = new CsvToListConverter(
    fieldDelimiter: '...*',
    textDelimiter: '...#',
    eol: '....',
    shouldParseNumbers: true);
final complex2Converter = new CsvToListConverter(
    fieldDelimiter: '...*',
    textDelimiter: '...#',
    eol: '.*.*',
    shouldParseNumbers: true);
final complex3Converter = new CsvToListConverter(
    fieldDelimiter: ',',
    textDelimiter: '.,a,b,__',
    eol: '_xyz',
    shouldParseNumbers: true);

main() {
  main_converter();

  main_transformer();

  test('Argument verification works', () {
    final parser = new CsvParser();
    expect(parser.verifyCurrentSettings(), equals([]));

    var errors =
        CsvParser.verifySettings('a', 'a', 'b', '\r\n', throwError: false);
    expect(errors.length, equals(1));
    expect(errors.first.runtimeType, equals(SettingsValuesEqualError));

    errors =
        CsvParser.verifySettings('a', null, 'b', '\r\n', throwError: false);
    expect(errors.length, equals(1));
    expect(errors.first.runtimeType, equals(TextDelimiterNullError));

    errors = CsvParser.verifySettings(null, 'a', null, 'a', throwError: false);
    expect(errors.length, equals(3));
    expect(errors.map((e) => e.runtimeType), contains(FieldDelimiterNullError));
    expect(
        errors.map((e) => e.runtimeType), contains(TextEndDelimiterNullError));
    expect(
        errors.map((e) => e.runtimeType), contains(SettingsValuesEqualError));
  });
}
