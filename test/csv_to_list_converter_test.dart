part of csv_to_list_test;


main_converter() {
  test('Csv converter has sane default values and stores parameters', () {
    expect(commaDoubleQuotCsvToListConverter.fieldDelimiters, equals([',']));
    expect(commaDoubleQuotCsvToListConverter.textDelimiters, equals(['"']));
    expect(commaDoubleQuotCsvToListConverter.textEndDelimiters, equals(['"']));
    expect(commaDoubleQuotCsvToListConverter.eols, equals(['\r\n']));
    expect(commaDoubleQuotCsvToListConverter.parseNumbers, equals(false));
    expect(commaDoubleQuotCsvToListConverterParseNumbers.parseNumbers,
           equals(true));
    expect(dotSingleQuotCsvToListConverterUnixEol.fieldDelimiters,
           equals(['.']));
    expect(dotSingleQuotCsvToListConverterUnixEol.textDelimiters, equals(["'"]));
    expect(dotSingleQuotCsvToListConverterUnixEol.textEndDelimiters,
           equals(["'"]));
    expect(dotSingleQuotCsvToListConverterUnixEol.eols, equals(['\n']));
    expect(dotSingleQuotCsvToListConverterUnixEol.parseNumbers, equals(false));

    expect(dotSingleQuotCsvToListConverterUnixEol_double.textEndDelimiters,
           equals(['"']));
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
                                          fieldDelimiters: ',',
                                          textDelimiters: '"',
                                          textEndDelimiters: '"',
                                          parseNumbers: true),
           equals([simpleStringsSingleRow]));
    expect(commaDoubleQuotCsvToListConverterParseNumbers
             .convert(csvSingleRowComma,
                      fieldDelimiters: ',',
                      textDelimiters: '"',
                      textEndDelimiters: '"',
                      parseNumbers: false),
           equals([singleRowAllText]));
    expect(aaBbCsvToListConverter.convert(csvSingleRowSemicolon,
                                          fieldDelimiters: ';',
                                          textDelimiters: '"',
                                          textEndDelimiters: '"',
                                          parseNumbers: true),
           equals([singleRow]));
    expect(aaBbCsvToListConverter.convert(csvSingleRowDotDoubleQuot,
                                          fieldDelimiters: '.',
                                          textDelimiters: '"',
                                          textEndDelimiters: '"',
                                          parseNumbers: true),
           equals([singleRowNoDouble]));
    expect(aaBbCsvToListConverter.convert(csvSingleRowDotSingleQuot,
                                          fieldDelimiters: '.',
                                          textDelimiters: "'",
                                          textEndDelimiters: "'",
                                          parseNumbers: true),
           equals([singleRowNoDouble]));
    expect(commaDoubleQuotCsvToListConverter.convert(csvSingleRowAaBb,
                                                     fieldDelimiters: 'aa',
                                                     textDelimiters: 'bb',
                                                     textEndDelimiters: 'bb',
                                                     parseNumbers: true),
           equals([singleRow]));
  });

  test('Can parse different formats when text end delimiter is different', () {
    expect(commaDoubleQuotCsvToListConverterParseNumbers
             .convert(csvSingleRowComma_endQuotXY,
                      textEndDelimiters: "XY"),
           equals([singleRow]));
    expect(semicolonDoubleQuotCsvToListConverter
             .convert(csvSingleRowSemicolon_endQuotXY,
                      parseNumbers: true,
                      textEndDelimiters: "XY"),
           equals([singleRow]));
    expect(dotDoubleQuotCsvToListConverter
             .convert(csvSingleRowDotDoubleQuot_endQuotXY,
                      parseNumbers: true,
                      textEndDelimiters: "XY"),
           equals([singleRowNoDouble]));
    expect(dotSingleQuotCsvToListConverterUnixEol
             .convert(csvSingleRowDotSingleQuot_endQuotDouble,
                      parseNumbers: true,
                      textEndDelimiters: '"'),
           equals([singleRowNoDouble]));
    expect(dotSingleQuotCsvToListConverterUnixEol_double
             .convert(csvSingleRowDotSingleQuot_endQuotDouble,
                      parseNumbers: true),
           equals([singleRowNoDouble]));
    expect(aaBbCsvToListConverter
             .convert(csvSingleRowAaBbXy,
                      parseNumbers: true,
                      textEndDelimiters: "XY"),
           equals([singleRow]));
  });

  test('Throw an exception if allowInvalid is false and field Delimiter and '
       'text Delimiter are equal or either is null', () {
    expect(() => new CsvToListConverter(fieldDelimiters: 'a',
                                        textDelimiters: 'a',
                                        allowInvalid: false).convert('a,b'),
           throwsArgumentError);
    expect(() => commaDoubleQuotCsvToListConverter
                   .convert('a,b',
                            fieldDelimiters: 'a',
                            textDelimiters: 'a',
                            allowInvalid: false),
           throwsArgumentError);
    expect(() => new CsvToListConverter(fieldDelimiters: null,
                                        textDelimiters: null,
                                        allowInvalid: false).convert('a,b'),
           throwsArgumentError);
  });

  test('Doesn\'t throw an exception if allowInvalid and field Delimiter and '
       'text Delimiter are equal or either is null', () {
    expect(new CsvToListConverter(fieldDelimiters: 'a',
                                  textDelimiters: 'a').convert('a,b'),
           isNotNull);
    expect(commaDoubleQuotCsvToListConverter
                   .convert('a,b',
                            fieldDelimiters: 'a',
                            textDelimiters: 'a'),
           isNotNull);
    expect(() => new CsvToListConverter(fieldDelimiters: null,
                                        textDelimiters: null).convert('a,b'),
           isNotNull);
  });


  test('Returns no rows for a null value', () =>
      expect(commaDoubleQuotCsvToListConverter.convert(null), equals([])));
  test('Returns no rows for an empty csv string', () =>
      expect(commaDoubleQuotCsvToListConverter.convert(''), equals([])));

  test('Parses a multiline csv string correctly (different eols)', () {
    var eol = commaDoubleQuotCsvToListConverterParseNumbers.eols.first;
    expect(eol, equals('\r\n'));
    var csv = csvSingleRowComma + eol +
              csvSingleRowComma + eol +
              csvSingleRowComma;
    expect(commaDoubleQuotCsvToListConverterParseNumbers.convert(csv),
           equals(multipleRows));

    eol = dotSingleQuotCsvToListConverterUnixEol.eols.first;
    expect(eol, equals('\n'));
    csv = csvSingleRowDotSingleQuot + eol +
          csvSingleRowDotSingleQuot + eol +
          csvSingleRowDotSingleQuot;
    expect(dotSingleQuotCsvToListConverterUnixEol.convert(csv),
           equals(multipleRowsAllText));
  });

  test('Throw an exception if allowInvalid is false and eol is null', () {
    expect(() => new CsvToListConverter(eols: null,
                                        allowInvalid: false).convert('a'),
           throwsArgumentError);
  });

  test('Doesn\'t throw an exception if allowInvalid and eol is null', () {
    expect(new CsvToListConverter(eols: null).convert('a'),
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
    expect(() => new CsvToListConverter(allowInvalid: false).convert(csv),
                 throwsFormatException);
  });

  test('Autodetecting settings works in converter mode', () {
    expect(aaBbCsvToListConverter.convert(csvSimpleStringsSingleRowComma,
                                          fieldDelimiters: [',', ';'],
                                          textDelimiters: ['"', "'"],
                                          textEndDelimiters: ['"', "'"],
                                          eols: ['\r\n', '\n'],
                                          parseNumbers: true),
           equals([simpleStringsSingleRow]));
    expect(commaDoubleQuotCsvToListConverterParseNumbers
             .convert(csvSingleRowComma,
                      fieldDelimiters: [',', 'b'],
                      textDelimiters: ["'", '"'],
                      textEndDelimiters: ['.', '"'],
                      eols: ['\n'],
                      parseNumbers: false),
           equals([singleRowAllText]));
    expect(commaDoubleQuotCsvToListConverter
             .convert(csvSingleRowAaBb,
                      fieldDelimiters: ['aa', '2'],
                      textDelimiters: ['bb', '"'],
                      textEndDelimiters: ['"', 'bb'],
                      parseNumbers: true),
           equals([singleRow]));

  });

  test('Autodetects settings for a multiline csv string correctly', () {
    var converter = new CsvToListConverter(eols: ['\r\n', '\n']);
    var eol = '\n';
    var csv = csvSingleRowComma + eol +
              csvSingleRowComma + eol +
              csvSingleRowComma;
    expect(converter.convert(csv),
           equals(multipleRows));

    csv = autodetectCsv;
    expect(new CsvToListConverter(eols: ['\r\n', '\n'],
                                  textDelimiters: ['""', "'"],
                                  textEndDelimiters: ['««', '!']).convert(csv),
           equals(autodetectRows));
  });

}