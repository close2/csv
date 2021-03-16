library csv_to_list_test;

import 'dart:async';

import 'package:test/test.dart';
import 'package:csv/csv.dart';
import 'package:csv/src/csv_parser.dart';
import 'package:csv/csv_settings_autodetection.dart';

import 'test_data.dart';

final commaDoubleQuotCsvToListConverter =
    CsvToListConverter(shouldParseNumbers: false);
final commaDoubleQuotCsvToListConverterParseNumbers = CsvToListConverter();
final semicolonDoubleQuotCsvToListConverter =
    CsvToListConverter(fieldDelimiter: ';', shouldParseNumbers: false);
final dotDoubleQuotCsvToListConverter =
    CsvToListConverter(fieldDelimiter: '.', shouldParseNumbers: false);
final dotSingleQuotCsvToListConverterUnixEol = CsvToListConverter(
    fieldDelimiter: '.',
    textDelimiter: "'",
    eol: '\n',
    shouldParseNumbers: false);
final dotSingleQuotCsvToListConverterUnixEol_double = CsvToListConverter(
    fieldDelimiter: '.',
    textDelimiter: "'",
    textEndDelimiter: '"',
    eol: '\n',
    shouldParseNumbers: false);
final aaBbCsvToListConverter = CsvToListConverter(
    fieldDelimiter: 'aa', textDelimiter: 'bb', shouldParseNumbers: false);
final complexConverter = CsvToListConverter(
    fieldDelimiter: '...*',
    textDelimiter: '...#',
    eol: '....',
    shouldParseNumbers: true);
final complex2Converter = CsvToListConverter(
    fieldDelimiter: '...*',
    textDelimiter: '...#',
    eol: '.*.*',
    shouldParseNumbers: true);
final complex3Converter = CsvToListConverter(
    fieldDelimiter: ',',
    textDelimiter: '.,a,b,__',
    eol: '_xyz',
    shouldParseNumbers: true);

void main() {
  main_converter();

  main_transformer();

  test('Argument verification works', () {
    final parser = CsvParser();
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

void main_transformer() {
  test('Works as transformer (simple test)', () {
    var stream = Stream.fromIterable([csvSimpleStringsSingleRowComma]);
    var f_rows = stream.transform(commaDoubleQuotCsvToListConverter).toList();
    expect(f_rows, completion([simpleStringsSingleRow]));
  });

  test('Works as transformer (complex multicharacter delimiters)', () {
    var csvStream = Stream.fromIterable(csvComplex_parts);
    var f_rows = csvStream.transform(complexConverter).toList();
    expect(f_rows, completion(complexRows));
  });

  test(
      'Works as transformer '
      '(complex multicharacter delimiters, difficult line endings)', () {
    var csvStream = Stream.fromIterable(csvComplex_parts_ending1);
    var f_rows = csvStream.transform(complexConverter).toList();
    expect(f_rows, completion(complexRows_ending1));

    var csvStream2 = Stream.fromIterable(csvComplex_parts_ending2);
    var f_rows2 = csvStream2.transform(complexConverter).toList();
    expect(f_rows2, completion(complexRows_ending2));
  });

  test(
      'Works as transformer '
      '(complex multicharacter delimiters, repeating patterns)', () {
    var csvStream = Stream.fromIterable(csvComplex2_parts);
    var f_rows = csvStream.transform(complex2Converter).toList();
    expect(f_rows, completion(complexRows2));
  });

  test(
      'Works as transformer '
      '(complex multicharacter delimiters, "embedded" patterns)', () {
    var csvStream = Stream.fromIterable(csvComplex3_parts);
    var f_rows = csvStream.transform(complex3Converter).toList();
    expect(f_rows, completion(complexRows3));
  });

  test(
      'Transformer throws an exception if not allowInvalid and csv ends '
      'without text end delimiter', () {
    const csv = ['abc,"d', 'ef,xyz'];
    final csvStream = Stream.fromIterable(csv);
    final converter = CsvToListConverter(allowInvalid: false);

    var fun = () => csvStream.transform(converter).toList();

    expect(fun(), throwsFormatException);
  });

  test('Transformer throws an exception if not allowInvalid and eol is null',
      () {
    var csvStream = Stream.fromIterable(csvComplex3_parts);
    final converter = CsvToListConverter(eol: null, allowInvalid: false);

    var fun = () => csvStream.transform(converter).toList();
    expect(fun(), throwsArgumentError);
  });

  test('Autodetecting settings works in transformer mode', () {
    var det = FirstOccurrenceSettingsDetector(
        fieldDelimiters: [',', ';'],
        textDelimiters: ['"', "'"],
        textEndDelimiters: ['"', "'"],
        eols: ['\r\n', '\n']);
    var converter =
        CsvToListConverter(csvSettingsDetector: det, shouldParseNumbers: true);
    var stream = Stream.fromIterable([csvSimpleStringsSingleRowComma]);
    var f_rows = stream.transform(converter).toList();
    expect(f_rows, completion([simpleStringsSingleRow]));

    det = FirstOccurrenceSettingsDetector(
        fieldDelimiters: [',', 'b'],
        textDelimiters: ["'", '"'],
        textEndDelimiters: ['.', '"'],
        eols: ['\n']);
    converter =
        CsvToListConverter(csvSettingsDetector: det, shouldParseNumbers: false);
    stream = Stream.fromIterable([csvSingleRowComma]);
    f_rows = stream.transform(converter).toList();
    expect(f_rows, completion([singleRowAllText]));

    det = FirstOccurrenceSettingsDetector(
        fieldDelimiters: ['aa', '2'],
        textDelimiters: ['bb', '"'],
        textEndDelimiters: ['"', 'bb']);
    converter =
        CsvToListConverter(csvSettingsDetector: det, shouldParseNumbers: true);
    stream = Stream.fromIterable([csvSingleRowAaBb]);
    f_rows = stream.transform(converter).toList();
    expect(f_rows, completion([singleRow]));
  });

  test('Transformer autodetects settings for a multiline csv correctly', () {
    var det = FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
    var converter = CsvToListConverter(csvSettingsDetector: det);
    var eol = '\n';
    var csvStream = Stream.fromIterable(
        [csvSingleRowComma, eol, csvSingleRowComma, eol, csvSingleRowComma]);
    var f_rows = csvStream.transform(converter).toList();
    expect(f_rows, completion(multipleRows));

    det = FirstOccurrenceSettingsDetector(
        eols: ['\r\n', '\n'],
        textDelimiters: ['""', "'"],
        textEndDelimiters: ['««', '!']);
    converter = CsvToListConverter(csvSettingsDetector: det);
    csvStream = Stream.fromIterable(autodetectCsv_parts);
    f_rows = csvStream.transform(converter).toList();
    expect(f_rows, completion(autodetectRows));
  });
}

void main_converter() {
  test('Csv converter has sane default values and stores parameters', () {
    expect(commaDoubleQuotCsvToListConverter.fieldDelimiter, equals(','));
    expect(commaDoubleQuotCsvToListConverter.textDelimiter, equals('"'));
    expect(commaDoubleQuotCsvToListConverter.textEndDelimiter, equals('"'));
    expect(commaDoubleQuotCsvToListConverter.eol, equals('\r\n'));
    expect(commaDoubleQuotCsvToListConverter.shouldParseNumbers, equals(false));
    expect(commaDoubleQuotCsvToListConverterParseNumbers.shouldParseNumbers,
        equals(true));
    expect(dotSingleQuotCsvToListConverterUnixEol.fieldDelimiter, equals('.'));
    expect(dotSingleQuotCsvToListConverterUnixEol.textDelimiter, equals("'"));
    expect(
        dotSingleQuotCsvToListConverterUnixEol.textEndDelimiter, equals("'"));
    expect(dotSingleQuotCsvToListConverterUnixEol.eol, equals('\n'));
    expect(dotSingleQuotCsvToListConverterUnixEol.shouldParseNumbers,
        equals(false));

    expect(dotSingleQuotCsvToListConverterUnixEol_double.textEndDelimiter,
        equals('"'));
  });

  test(
      'Can parse different formats of csv into a list without parsing '
      'numbers', () {
    expect(
        commaDoubleQuotCsvToListConverter
            .convert(csvSimpleStringsSingleRowComma),
        equals([simpleStringsSingleRow]));
    expect(commaDoubleQuotCsvToListConverter.convert(csvSingleRowComma),
        equals([singleRowAllText]));
    expect(semicolonDoubleQuotCsvToListConverter.convert(csvSingleRowSemicolon),
        equals([singleRowAllText]));
    expect(dotDoubleQuotCsvToListConverter.convert(csvSingleRowDotDoubleQuot),
        equals([singleRowAllText]));
    expect(
        dotSingleQuotCsvToListConverterUnixEol
            .convert(csvSingleRowDotSingleQuot),
        equals([singleRowAllText]));
    expect(aaBbCsvToListConverter.convert(csvSingleRowAaBb),
        equals([singleRowAllText]));
  });

  test('Can parse different formats of csv with number-parsing', () {
    expect(
        commaDoubleQuotCsvToListConverterParseNumbers
            .convert(csvSimpleStringsSingleRowComma),
        equals([simpleStringsSingleRow]));
    expect(
        commaDoubleQuotCsvToListConverterParseNumbers
            .convert(csvSingleRowComma),
        equals([singleRow]));
    expect(
        semicolonDoubleQuotCsvToListConverter.convert(csvSingleRowSemicolon,
            shouldParseNumbers: true),
        equals([singleRow]));
    expect(
        dotDoubleQuotCsvToListConverter.convert(csvSingleRowDotDoubleQuot,
            shouldParseNumbers: true),
        equals([singleRowNoDouble]));
    expect(
        dotSingleQuotCsvToListConverterUnixEol
            .convert(csvSingleRowDotSingleQuot, shouldParseNumbers: true),
        equals([singleRowNoDouble]));
    expect(
        aaBbCsvToListConverter.convert(csvSingleRowAaBb,
            shouldParseNumbers: true),
        equals([singleRow]));
  });

  test('Can override field, text (end) delimiter and shouldParseNumbers', () {
    expect(
        aaBbCsvToListConverter.convert(csvSimpleStringsSingleRowComma,
            fieldDelimiter: ',',
            textDelimiter: '"',
            textEndDelimiter: '"',
            shouldParseNumbers: true),
        equals([simpleStringsSingleRow]));
    expect(
        commaDoubleQuotCsvToListConverterParseNumbers.convert(csvSingleRowComma,
            fieldDelimiter: ',',
            textDelimiter: '"',
            textEndDelimiter: '"',
            shouldParseNumbers: false),
        equals([singleRowAllText]));
    expect(
        aaBbCsvToListConverter.convert(csvSingleRowSemicolon,
            fieldDelimiter: ';',
            textDelimiter: '"',
            textEndDelimiter: '"',
            shouldParseNumbers: true),
        equals([singleRow]));
    expect(
        aaBbCsvToListConverter.convert(csvSingleRowDotDoubleQuot,
            fieldDelimiter: '.',
            textDelimiter: '"',
            textEndDelimiter: '"',
            shouldParseNumbers: true),
        equals([singleRowNoDouble]));
    expect(
        aaBbCsvToListConverter.convert(csvSingleRowDotSingleQuot,
            fieldDelimiter: '.',
            textDelimiter: "'",
            textEndDelimiter: "'",
            shouldParseNumbers: true),
        equals([singleRowNoDouble]));
    expect(
        commaDoubleQuotCsvToListConverter.convert(csvSingleRowAaBb,
            fieldDelimiter: 'aa',
            textDelimiter: 'bb',
            textEndDelimiter: 'bb',
            shouldParseNumbers: true),
        equals([singleRow]));
  });

  test('Can parse different formats when text end delimiter is different', () {
    expect(
        commaDoubleQuotCsvToListConverterParseNumbers
            .convert(csvSingleRowComma_endQuotXY, textEndDelimiter: 'XY'),
        equals([singleRow]));
    expect(
        semicolonDoubleQuotCsvToListConverter.convert(
            csvSingleRowSemicolon_endQuotXY,
            shouldParseNumbers: true,
            textEndDelimiter: "XY"),
        equals([singleRow]));
    expect(
        dotDoubleQuotCsvToListConverter.convert(
            csvSingleRowDotDoubleQuot_endQuotXY,
            shouldParseNumbers: true,
            textEndDelimiter: "XY"),
        equals([singleRowNoDouble]));
    expect(
        dotSingleQuotCsvToListConverterUnixEol.convert(
            csvSingleRowDotSingleQuot_endQuotDouble,
            shouldParseNumbers: true,
            textEndDelimiter: '"'),
        equals([singleRowNoDouble]));
    expect(
        dotSingleQuotCsvToListConverterUnixEol_double.convert(
            csvSingleRowDotSingleQuot_endQuotDouble,
            shouldParseNumbers: true),
        equals([singleRowNoDouble]));
    expect(
        aaBbCsvToListConverter.convert(csvSingleRowAaBbXy,
            shouldParseNumbers: true, textEndDelimiter: 'XY'),
        equals([singleRow]));
  });

  test(
      'Throw an exception if allowInvalid is false and field Delimiter and '
      'text Delimiter are equal or either is null', () {
    expect(
        () => CsvToListConverter(
                fieldDelimiter: 'a', textDelimiter: 'a', allowInvalid: false)
            .convert('a,b'),
        throwsArgumentError);
    expect(
        () => commaDoubleQuotCsvToListConverter.convert('a,b',
            fieldDelimiter: 'a', textDelimiter: 'a', allowInvalid: false),
        throwsArgumentError);
    expect(
        () => CsvToListConverter(
                fieldDelimiter: null, textDelimiter: null, allowInvalid: false)
            .convert('a,b'),
        throwsArgumentError);
  });

  test(
      'Doesn\'t throw an exception if allowInvalid and field Delimiter and '
      'text Delimiter are equal or either is null', () {
    expect(
        CsvToListConverter(fieldDelimiter: 'a', textDelimiter: 'a')
            .convert('a,b'),
        isNotNull);
    expect(
        commaDoubleQuotCsvToListConverter.convert('a,b',
            fieldDelimiter: 'a', textDelimiter: 'a'),
        isNotNull);
    expect(
        () => CsvToListConverter(fieldDelimiter: null, textDelimiter: null)
            .convert('a,b'),
        isNotNull);
  });

  test(
      'Returns no rows for a null value',
      () =>
          expect(commaDoubleQuotCsvToListConverter.convert(null), equals([])));
  test('Returns no rows for an empty csv string',
      () => expect(commaDoubleQuotCsvToListConverter.convert(''), equals([])));

  test('Parses a multiline csv string correctly (different eols)', () {
    var eol = commaDoubleQuotCsvToListConverterParseNumbers.eol!;
    expect(eol, equals('\r\n'));
    var csv =
        csvSingleRowComma + eol + csvSingleRowComma + eol + csvSingleRowComma;
    expect(commaDoubleQuotCsvToListConverterParseNumbers.convert(csv),
        equals(multipleRows));

    eol = dotSingleQuotCsvToListConverterUnixEol.eol!;
    expect(eol, equals('\n'));
    csv = csvSingleRowDotSingleQuot +
        eol +
        csvSingleRowDotSingleQuot +
        eol +
        csvSingleRowDotSingleQuot;
    expect(dotSingleQuotCsvToListConverterUnixEol.convert(csv),
        equals(multipleRowsAllText));
  });

  test('Throw an exception if allowInvalid is false and eol is null', () {
    expect(
        () => CsvToListConverter(eol: null, allowInvalid: false).convert('a'),
        throwsArgumentError);
  });

  test('Doesn\'t throw an exception if allowInvalid and eol is null', () {
    expect(
        CsvToListConverter(eol: null).convert('a'),
        equals([
          ['a']
        ]));
  });

  test('Parses complex csv representation', () {
    expect(complexConverter.convert(csvComplexRows), equals(complexRows));
  });

  test('Parses complex csv representation with difficult line endings', () {
    expect(complexConverter.convert(csvComplexRows_ending1),
        equals(complexRows_ending1));
    expect(complexConverter.convert(csvComplexRows_ending2),
        equals(complexRows_ending2));
  });

  test('Parses complex csv representation with repeating patterns', () {
    expect(complex2Converter.convert(csvComplex2Rows), equals(complexRows2));
  });

  test('Parses complex csv representation with "embedded" patterns', () {
    expect(complex3Converter.convert(csvComplex3Rows), equals(complexRows3));
  });

  test(
      'Throws an exception if not allowInvalid and csv ends without '
      'text end delimiter', () {
    const csv = 'abc,"def,xyz';
    expect(() => CsvToListConverter(allowInvalid: false).convert(csv),
        throwsFormatException);
  });

  test('Autodetecting settings works in converter mode', () {
    var det = FirstOccurrenceSettingsDetector(
        fieldDelimiters: [',', ';'],
        textDelimiters: ['"', "'"],
        textEndDelimiters: ['"', "'"],
        eols: ['\r\n', '\n']);
    expect(
        aaBbCsvToListConverter.convert(csvSimpleStringsSingleRowComma,
            csvSettingsDetector: det, shouldParseNumbers: true),
        equals([simpleStringsSingleRow]));

    det = FirstOccurrenceSettingsDetector(
        fieldDelimiters: [',', 'b'],
        textDelimiters: ["'", '"'],
        textEndDelimiters: ['.', '"'],
        eols: ['\n']);
    expect(
        commaDoubleQuotCsvToListConverterParseNumbers.convert(csvSingleRowComma,
            csvSettingsDetector: det, shouldParseNumbers: false),
        equals([singleRowAllText]));

    det = FirstOccurrenceSettingsDetector(
        fieldDelimiters: ['aa', '2'],
        textDelimiters: ['bb', '"'],
        textEndDelimiters: ['"', 'bb']);
    expect(
        commaDoubleQuotCsvToListConverter.convert(csvSingleRowAaBb,
            csvSettingsDetector: det, shouldParseNumbers: true),
        equals([singleRow]));
  });

  test('Autodetects settings for a multiline csv string correctly', () {
    var det = FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
    var converter = CsvToListConverter(csvSettingsDetector: det);
    var eol = '\n';
    var csv =
        csvSingleRowComma + eol + csvSingleRowComma + eol + csvSingleRowComma;
    expect(converter.convert(csv), equals(multipleRows));

    det = FirstOccurrenceSettingsDetector(
        eols: ['\r\n', '\n'],
        textDelimiters: ['""', "'"],
        textEndDelimiters: ['««', '!']);
    csv = autodetectCsv;
    expect(CsvToListConverter(csvSettingsDetector: det).convert(csv),
        equals(autodetectRows));
  });
}
