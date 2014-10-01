library csv2list_test;


import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:csv/csv.dart';
import 'package:csv/src/csv_parser.dart';

import 'test_data.dart';


main() {
  const commaDoubleQuotCsvToListConverter =
      const Csv2ListConverter(parseNumbers: false);
  const commaDoubleQuotCsvToListConverterParseNumbers =
      const Csv2ListConverter();
  const semicolonDoubleQuotCsvToListConverter =
      const Csv2ListConverter(fieldDelimiter: ';',
                              parseNumbers: false);
  const dotDoubleQuotCsvToListConverter =
      const Csv2ListConverter(fieldDelimiter: '.',
                              parseNumbers: false);
  const dotSingleQuotCsvToListConverterUnixEol =
      const Csv2ListConverter(fieldDelimiter: '.',
                              textDelimiter: "'",
                              eol: '\n',
                              parseNumbers: false);
  const dotSingleQuotCsvToListConverterUnixEol_double =
      const Csv2ListConverter(fieldDelimiter: '.',
                              textDelimiter: "'",
                              textEndDelimiter: '"',
                              eol: '\n',
                              parseNumbers: false);
  const aaBbCsvToListConverter =
      const Csv2ListConverter(fieldDelimiter: 'aa',
                              textDelimiter: 'bb',
                              parseNumbers: false);
  const complexConverter =
      const Csv2ListConverter(fieldDelimiter: '...*',
                              textDelimiter: '...#',
                              eol: '....',
                              parseNumbers: true);
  const complex2Converter =
      const Csv2ListConverter(fieldDelimiter: '...*',
                              textDelimiter: '...#',
                              eol: '.*.*',
                              parseNumbers: true);
  const complex3Converter =
      const Csv2ListConverter(fieldDelimiter: ',',
                              textDelimiter: '.,a,b,__',
                              eol: '_xyz',
                              parseNumbers: true);


  test('Csv converter has sane default values and stores parameters', () {
    expect(commaDoubleQuotCsvToListConverter.fieldDelimiter, equals(','));
    expect(commaDoubleQuotCsvToListConverter.textDelimiter, equals('"'));
    expect(commaDoubleQuotCsvToListConverter.textEndDelimiter, equals('"'));
    expect(commaDoubleQuotCsvToListConverter.eol, equals('\r\n'));
    expect(commaDoubleQuotCsvToListConverter.parseNumbers, equals(false));
    expect(commaDoubleQuotCsvToListConverterParseNumbers.parseNumbers,
           equals(true));
    expect(dotSingleQuotCsvToListConverterUnixEol.fieldDelimiter, equals('.'));
    expect(dotSingleQuotCsvToListConverterUnixEol.textDelimiter, equals("'"));
    expect(dotSingleQuotCsvToListConverterUnixEol.textEndDelimiter,
           equals("'"));
    expect(dotSingleQuotCsvToListConverterUnixEol.eol, equals('\n'));
    expect(dotSingleQuotCsvToListConverterUnixEol.parseNumbers, equals(false));

    expect(dotSingleQuotCsvToListConverterUnixEol_double.textEndDelimiter,
           equals('"'));
  });


  test('Can parse different formats of csv into a list without parsing '
      'numbers', () {
    expect(commaDoubleQuotCsvToListConverter
             .convert(csvSimpleStringsSingleRowComma),
           equals([simpleStringsSingleRow]));
    expect(commaDoubleQuotCsvToListConverter.convert(csvSingleRowComma),
           equals([singleRowAllText]));
    expect(semicolonDoubleQuotCsvToListConverter
             .convert(csvSingleRowSemicolon),
           equals([singleRowAllText]));
    expect(dotDoubleQuotCsvToListConverter.convert(csvSingleRowDotDoubleQuot),
           equals([singleRowAllText]));
    expect(dotSingleQuotCsvToListConverterUnixEol
             .convert(csvSingleRowDotSingleQuot),
           equals([singleRowAllText]));
    expect(aaBbCsvToListConverter.convert(csvSingleRowAaBb),
           equals([singleRowAllText]));
  });

  test('Can parse different formats of csv with number-parsing', () {
    expect(commaDoubleQuotCsvToListConverterParseNumbers
             .convert(csvSimpleStringsSingleRowComma),
           equals([simpleStringsSingleRow]));
    expect(commaDoubleQuotCsvToListConverterParseNumbers
             .convert(csvSingleRowComma),
           equals([singleRow]));
    expect(semicolonDoubleQuotCsvToListConverter
             .convert(csvSingleRowSemicolon, parseNumbers: true),
           equals([singleRow]));
    expect(dotDoubleQuotCsvToListConverter
             .convert(csvSingleRowDotDoubleQuot, parseNumbers: true),
           equals([singleRowNoDouble]));
    expect(dotSingleQuotCsvToListConverterUnixEol
             .convert(csvSingleRowDotSingleQuot, parseNumbers: true),
           equals([singleRowNoDouble]));
    expect(aaBbCsvToListConverter
             .convert(csvSingleRowAaBb, parseNumbers: true),
           equals([singleRow]));
  });


  test('Can override field, text (end) delimiter and parseNumbers', () {
    expect(aaBbCsvToListConverter.convert(csvSimpleStringsSingleRowComma,
                                          fieldDelimiter: ',',
                                          textDelimiter: '"',
                                          textEndDelimiter: '"',
                                          parseNumbers: true),
           equals([simpleStringsSingleRow]));
    expect(commaDoubleQuotCsvToListConverterParseNumbers
             .convert(csvSingleRowComma,
                      fieldDelimiter: ',',
                      textDelimiter: '"',
                      textEndDelimiter: '"',
                      parseNumbers: false),
           equals([singleRowAllText]));
    expect(aaBbCsvToListConverter.convert(csvSingleRowSemicolon,
                                          fieldDelimiter: ';',
                                          textDelimiter: '"',
                                          textEndDelimiter: '"',
                                          parseNumbers: true),
           equals([singleRow]));
    expect(aaBbCsvToListConverter.convert(csvSingleRowDotDoubleQuot,
                                          fieldDelimiter: '.',
                                          textDelimiter: '"',
                                          textEndDelimiter: '"',
                                          parseNumbers: true),
           equals([singleRowNoDouble]));
    expect(aaBbCsvToListConverter.convert(csvSingleRowDotSingleQuot,
                                          fieldDelimiter: '.',
                                          textDelimiter: "'",
                                          textEndDelimiter: "'",
                                          parseNumbers: true),
           equals([singleRowNoDouble]));
    expect(commaDoubleQuotCsvToListConverter.convert(csvSingleRowAaBb,
                                                     fieldDelimiter: 'aa',
                                                     textDelimiter: 'bb',
                                                     textEndDelimiter: 'bb',
                                                     parseNumbers: true),
           equals([singleRow]));
  });

  test('Can parse different formats when text end delimiter is different', () {
    expect(commaDoubleQuotCsvToListConverterParseNumbers
             .convert(csvSingleRowComma_endQuotXY,
                      textEndDelimiter: "XY"),
           equals([singleRow]));
    expect(semicolonDoubleQuotCsvToListConverter
             .convert(csvSingleRowSemicolon_endQuotXY,
                      parseNumbers: true,
                      textEndDelimiter: "XY"),
           equals([singleRow]));
    expect(dotDoubleQuotCsvToListConverter
             .convert(csvSingleRowDotDoubleQuot_endQuotXY,
                      parseNumbers: true,
                      textEndDelimiter: "XY"),
           equals([singleRowNoDouble]));
    expect(dotSingleQuotCsvToListConverterUnixEol
             .convert(csvSingleRowDotSingleQuot_endQuotDouble,
                      parseNumbers: true,
                      textEndDelimiter: '"'),
           equals([singleRowNoDouble]));
    expect(dotSingleQuotCsvToListConverterUnixEol_double
             .convert(csvSingleRowDotSingleQuot_endQuotDouble,
                      parseNumbers: true),
           equals([singleRowNoDouble]));
    expect(aaBbCsvToListConverter
             .convert(csvSingleRowAaBbXy,
                      parseNumbers: true,
                      textEndDelimiter: "XY"),
           equals([singleRow]));
  });

  test('Throw an exception if allowInvalid is false and field Delimiter and '
       'text Delimiter are equal or either is null', () {
    expect(() => new Csv2ListConverter(fieldDelimiter: 'a',
                                       textDelimiter: 'a',
                                       allowInvalid: false).convert('a,b'),
           throwsArgumentError);
    expect(() => commaDoubleQuotCsvToListConverter
                   .convert('a,b',
                            fieldDelimiter: 'a',
                            textDelimiter: 'a',
                            allowInvalid: false),
           throwsArgumentError);
    expect(() => new Csv2ListConverter(fieldDelimiter: null,
                                       textDelimiter: null,
                                       allowInvalid: false).convert('a,b'),
           throwsArgumentError);
  });

  test('Doesn\'t throw an exception if allowInvalid and field Delimiter and '
       'text Delimiter are equal or either is null', () {
    expect(new Csv2ListConverter(fieldDelimiter: 'a',
                                 textDelimiter: 'a').convert('a,b'),
           isNotNull);
    expect(commaDoubleQuotCsvToListConverter
                   .convert('a,b',
                            fieldDelimiter: 'a',
                            textDelimiter: 'a'),
           isNotNull);
    expect(() => new Csv2ListConverter(fieldDelimiter: null,
                                       textDelimiter: null).convert('a,b'),
           isNotNull);
  });


  test('Returns no rows for a null value', () =>
      expect(commaDoubleQuotCsvToListConverter.convert(null), equals([])));
  test('Returns no rows for an empty csv string', () =>
      expect(commaDoubleQuotCsvToListConverter.convert(''), equals([])));

  test('Parses a multiline csv string correctly (different eols)', () {
    var eol = commaDoubleQuotCsvToListConverterParseNumbers.eol;
    expect(eol, equals('\r\n'));
    var csv = csvSingleRowComma + eol +
              csvSingleRowComma + eol +
              csvSingleRowComma;
    expect(commaDoubleQuotCsvToListConverterParseNumbers.convert(csv),
           equals(multipleRows));

    eol = dotSingleQuotCsvToListConverterUnixEol.eol;
    expect(eol, equals('\n'));
    csv = csvSingleRowDotSingleQuot + eol +
          csvSingleRowDotSingleQuot + eol +
          csvSingleRowDotSingleQuot;
    expect(dotSingleQuotCsvToListConverterUnixEol.convert(csv),
           equals(multipleRowsAllText));
  });

  test('Throw an exception if allowInvalid is false and eol is null', () {
    expect(() => new Csv2ListConverter(eol: null,
                                       allowInvalid: false).convert('a'),
           throwsArgumentError);
  });

  test('Doesn\'t throw an exception if allowInvalid and eol is null', () {
    expect(new Csv2ListConverter(eol: null).convert('a'),
           equals([['a']]));
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
    expect(complex2Converter.convert(csvComplex2Rows),
           equals(complexRows2));
  });

  test('Parses complex csv representation with "embedded" patterns', () {
    expect(complex3Converter.convert(csvComplex3Rows),
           equals(complexRows3));
  });


  test('Throws an exception if not allowInvalid and csv ends without '
       'text end delimiter', () {
    const String csv = 'abc,"def,xyz';
    expect(() => new Csv2ListConverter(allowInvalid: false).convert(csv),
                 throwsFormatException);
  });


  test('Works as transformer (simple test)', () {
    var stream = new Stream.fromIterable([csvSimpleStringsSingleRowComma]);
    var f_rows = stream.transform(commaDoubleQuotCsvToListConverter).toList();
    expect(f_rows, completion([simpleStringsSingleRow]));
  });

  test('Works as transformer (complex multicharacter delimiters)', () {
    var csvStream = new Stream.fromIterable(csvComplex_parts);
    var f_rows = csvStream.transform(complexConverter).toList();
    expect(f_rows, completion(complexRows));
  });

  test('Works as transformer '
       '(complex multicharacter delimiters, difficult line endings)', () {
    var csvStream = new Stream.fromIterable(csvComplex_parts_ending1);
    var f_rows = csvStream.transform(complexConverter).toList();
    expect(f_rows, completion(complexRows_ending1));

    var csvStream2 = new Stream.fromIterable(csvComplex_parts_ending2);
    var f_rows2 = csvStream2.transform(complexConverter).toList();
    expect(f_rows2, completion(complexRows_ending2));
  });

  test('Works as transformer '
       '(complex multicharacter delimiters, repeating patterns)', () {
    var csvStream = new Stream.fromIterable(csvComplex2_parts);
    var f_rows = csvStream.transform(complex2Converter).toList();
    expect(f_rows, completion(complexRows2));
  });

  test('Works as transformer '
       '(complex multicharacter delimiters, "embedded" patterns)', () {
    var csvStream = new Stream.fromIterable(csvComplex3_parts);
    var f_rows = csvStream.transform(complex3Converter).toList();
    expect(f_rows, completion(complexRows3));
  });

  test('Transformer throws an exception if not allowInvalid and csv ends '
       'without text end delimiter', () {
    const List<String> csv = const ['abc,"d','ef,xyz'];
    final csvStream = new Stream.fromIterable(csv);
    final converter = new Csv2ListConverter(allowInvalid: false);
    var f_rows = csvStream.transform(converter).toList();
    expect(f_rows, throwsFormatException);
  });

  test('Transformer throws an exception if not allowInvalid and eol is null',
       () {
    var csvStream = new Stream.fromIterable(csvComplex3_parts);
    final converter = new Csv2ListConverter(eol: null, allowInvalid: false);
    var f_rows = csvStream.transform(converter);
    expect(() => f_rows.toList(), throwsArgumentError);
  });



  test('Argument verification works', () {
    final parser = new CsvParser();
    expect(parser.verifyCurrentSettings(), equals([]));

    var errors = parser.verifySettings('a', 'a', 'b', '\r\n', throwError: false);
    expect(errors.length, equals(1));
    expect(errors.first.runtimeType, equals(SettingsValuesEqualError));

    errors = parser.verifySettings('a', null, 'b', '\r\n', throwError: false);
    expect(errors.length, equals(1));
    expect(errors.first.runtimeType, equals(TextDelimiterNullError));

    errors = parser.verifySettings(null, 'a', null, 'a', throwError: false);
    expect(errors.length, equals(3));
    expect(errors.map((e) => e.runtimeType), contains(FieldDelimiterNullError));
    expect(errors.map((e) => e.runtimeType), contains(TextEndDelimiterNullError));
    expect(errors.map((e) => e.runtimeType), contains(SettingsValuesEqualError));
  });
}