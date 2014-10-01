library list2csv_test;


import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:csv/csv.dart';

import 'test_data.dart';


main() {

  const commaDoubleQuotListToCsvConverter =
      const List2CsvConverter();
  const semicolonDoubleQuotListToCsvConverter =
      const List2CsvConverter(fieldDelimiter: ';');
  const dotDoubleQuotListToCsvConverter =
      const List2CsvConverter(fieldDelimiter: '.');
  const dotSingleQuotListToCsvConverterUnixEol =
      const List2CsvConverter(fieldDelimiter: '.',
                              textDelimiter: "'",
                              eol: '\n');
  const aaBbListToCsvConverter =
      const List2CsvConverter(fieldDelimiter: 'aa', textDelimiter: 'bb');

  const commaDoubleQuotListToCsvConverter_xy =
      const List2CsvConverter(textEndDelimiter: 'XY');
  const semicolonDoubleQuotListToCsvConverter_xy =
      const List2CsvConverter(fieldDelimiter: ';',
                              textEndDelimiter: 'XY');
  const dotDoubleQuotListToCsvConverter_xy =
      const List2CsvConverter(fieldDelimiter: '.',
                              textEndDelimiter: 'XY');
  const dotSingleQuotListToCsvConverterUnixEol_double =
      const List2CsvConverter(fieldDelimiter: '.',
                              textDelimiter: "'",
                              textEndDelimiter: '"',
                              eol: '\n');
  const aaBbListToCsvConverter_xy =
      const List2CsvConverter(fieldDelimiter: 'aa',
                              textDelimiter: 'bb',
                              textEndDelimiter: 'XY');



  test('Csv converter has sane default values and stores parameters', () {
    expect(commaDoubleQuotListToCsvConverter.fieldDelimiter, equals(','));
    expect(commaDoubleQuotListToCsvConverter.textDelimiter, equals('"'));
    expect(commaDoubleQuotListToCsvConverter.textEndDelimiter, equals('"'));
    expect(const List2CsvConverter(textEndDelimiter: 'abc').textEndDelimiter,
           equals('abc'));
    expect(commaDoubleQuotListToCsvConverter.eol, equals('\r\n'));
    expect(dotSingleQuotListToCsvConverterUnixEol.fieldDelimiter, equals('.'));
    expect(dotSingleQuotListToCsvConverterUnixEol.textDelimiter, equals("'"));
    expect(dotSingleQuotListToCsvConverterUnixEol.eol, equals('\n'));
  });


  var sb = new StringBuffer();

  test('A single simple row converts into a separated value string '
       '(different field delimiters)', () {
    commaDoubleQuotListToCsvConverter.convertSingleRow(sb..clear(), singleRow);
    expect(sb.toString(), equals(csvSingleRowComma));

    semicolonDoubleQuotListToCsvConverter.convertSingleRow(sb..clear(),
                                                           singleRow);
    expect(sb.toString(), equals(csvSingleRowSemicolon));
  });

  test('A single simple row where quoting is necessary converts '
       '(different field and text delimiters)', () {
    dotDoubleQuotListToCsvConverter.convertSingleRow(sb..clear(), singleRow);
    expect(sb.toString(), equals(csvSingleRowDotDoubleQuot));
    dotSingleQuotListToCsvConverterUnixEol.convertSingleRow(sb..clear(),
                                                            singleRow);
    expect(sb.toString(), equals(csvSingleRowDotSingleQuot));
    aaBbListToCsvConverter.convertSingleRow(sb..clear(), singleRow);
    expect(sb.toString(), equals(csvSingleRowAaBb));
  });

  test('Converts a single row where textDelimiter is different to '
       'textEndDelimiter', () {
    commaDoubleQuotListToCsvConverter_xy.convertSingleRow(sb..clear(),
                                                          singleRow);
    expect(sb.toString(), equals(csvSingleRowComma_endQuotXY));

    semicolonDoubleQuotListToCsvConverter_xy.convertSingleRow(sb..clear(),
                                                              singleRow);
    expect(sb.toString(), equals(csvSingleRowSemicolon_endQuotXY));
    dotDoubleQuotListToCsvConverter_xy.convertSingleRow(sb..clear(),
                                                        singleRow);
    expect(sb.toString(), equals(csvSingleRowDotDoubleQuot_endQuotXY));
    dotSingleQuotListToCsvConverterUnixEol_double.convertSingleRow(sb..clear(),
                                                                   singleRow);
    expect(sb.toString(), equals(csvSingleRowDotSingleQuot_endQuotDouble));
    aaBbListToCsvConverter_xy.convertSingleRow(sb..clear(), singleRow);
    expect(sb.toString(), equals(csvSingleRowAaBbXy));
  });

  test("Can override field and text delimiter", () {
    dotSingleQuotListToCsvConverterUnixEol
      .convertSingleRow(sb..clear(),
                        singleRow,
                        fieldDelimiter: ',',
                        textDelimiter: '"',
                        textEndDelimiter: '"');
    expect(sb.toString(), equals(csvSingleRowComma));
  });

  test('Throw an exception if field Delimiter and text Delimiter are equal or '
       'either is null', () {
    sb.clear();
    expect(() {
        var converter = new List2CsvConverter(fieldDelimiter: 'a',
                                              textDelimiter: 'a');
        converter.convertSingleRow(sb, singleRow);
      }, throwsArgumentError);
    expect(() {
        var converter = commaDoubleQuotListToCsvConverter;
        converter.convertSingleRow(sb,
                                   singleRow,
                                   fieldDelimiter: 'a',
                                   textDelimiter: 'a');
      }, throwsArgumentError);
    expect(() {
        new List2CsvConverter(fieldDelimiter: null,
                              textDelimiter: null).convertSingleRow(sb,
                                                                    singleRow);
      }, throwsArgumentError);
  });

  test('Returns empty string when the row is null or an empty list', () {
    commaDoubleQuotListToCsvConverter.convertSingleRow(sb..clear(), null);
    expect(sb.toString(), equals(''));
    commaDoubleQuotListToCsvConverter.convertSingleRow(sb..clear(), []);
    expect(sb.toString(), equals(''));
  });

  test('Multiple rows are correctly appended with the eol character '
       '(different eols)', () {
    var eol = commaDoubleQuotListToCsvConverter.eol;
    expect(eol, equals('\r\n'));
    expect(commaDoubleQuotListToCsvConverter.convert(multipleRows),
           equals(csvSingleRowComma + eol +
                  csvSingleRowComma + eol +
                  csvSingleRowComma));

    eol = dotSingleQuotListToCsvConverterUnixEol.eol;
    expect(eol, equals('\n'));
    expect(dotSingleQuotListToCsvConverterUnixEol.convert(multipleRows),
           equals(csvSingleRowDotSingleQuot + eol +
                  csvSingleRowDotSingleQuot + eol +
                  csvSingleRowDotSingleQuot));
  });

  test('Can override field and text delimiter and eol', () {
    var eol = '**\n';
    final converter = dotSingleQuotListToCsvConverterUnixEol;
    expect(converter.convert(multipleRows,
                             fieldDelimiter: ',',
                             textDelimiter: '"',
                             textEndDelimiter: '"',
                             eol: eol),
           equals(csvSingleRowComma + eol +
                  csvSingleRowComma + eol +
                  csvSingleRowComma));
  });

  test('Returns an empty string when rows is null or empty', () {
    expect(commaDoubleQuotListToCsvConverter.convert(null),
           equals(''));
    expect(commaDoubleQuotListToCsvConverter.convert([]),
           equals(''));
  });

  test('Throw an exception if eol is null', () {
    expect(() => new List2CsvConverter(eol: null).convert(singleRow),
           throwsArgumentError);
  });


  var multipleRowsStream = new Stream.fromIterable(multipleRows);
  test('Works as transformer', () {
    var eol = commaDoubleQuotListToCsvConverter.eol;
    var result = csvSingleRowComma + eol +
                 csvSingleRowComma + eol +
                 csvSingleRowComma + eol;
    var f_csv = multipleRowsStream.transform(commaDoubleQuotListToCsvConverter).join();
    expect(f_csv, completion(result));
  });

}