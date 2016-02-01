part of csv_to_list_test;

main_converter() {
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
            .convert(csvSingleRowComma_endQuotXY, textEndDelimiter: "XY"),
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
            shouldParseNumbers: true, textEndDelimiter: "XY"),
        equals([singleRow]));
  });

  test(
      'Throw an exception if allowInvalid is false and field Delimiter and '
      'text Delimiter are equal or either is null', () {
    expect(
        () => new CsvToListConverter(
                fieldDelimiter: 'a', textDelimiter: 'a', allowInvalid: false)
            .convert('a,b'),
        throwsArgumentError);
    expect(
        () => commaDoubleQuotCsvToListConverter.convert('a,b',
            fieldDelimiter: 'a', textDelimiter: 'a', allowInvalid: false),
        throwsArgumentError);
    expect(
        () => new CsvToListConverter(
                fieldDelimiter: null, textDelimiter: null, allowInvalid: false)
            .convert('a,b'),
        throwsArgumentError);
  });

  test(
      'Doesn\'t throw an exception if allowInvalid and field Delimiter and '
      'text Delimiter are equal or either is null', () {
    expect(
        new CsvToListConverter(fieldDelimiter: 'a', textDelimiter: 'a')
            .convert('a,b'),
        isNotNull);
    expect(
        commaDoubleQuotCsvToListConverter.convert('a,b',
            fieldDelimiter: 'a', textDelimiter: 'a'),
        isNotNull);
    expect(
        () => new CsvToListConverter(fieldDelimiter: null, textDelimiter: null)
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
    var eol = commaDoubleQuotCsvToListConverterParseNumbers.eol;
    expect(eol, equals('\r\n'));
    var csv =
        csvSingleRowComma + eol + csvSingleRowComma + eol + csvSingleRowComma;
    expect(commaDoubleQuotCsvToListConverterParseNumbers.convert(csv),
        equals(multipleRows));

    eol = dotSingleQuotCsvToListConverterUnixEol.eol;
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
        () =>
            new CsvToListConverter(eol: null, allowInvalid: false).convert('a'),
        throwsArgumentError);
  });

  test('Doesn\'t throw an exception if allowInvalid and eol is null', () {
    expect(
        new CsvToListConverter(eol: null).convert('a'),
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
    const String csv = 'abc,"def,xyz';
    expect(() => new CsvToListConverter(allowInvalid: false).convert(csv),
        throwsFormatException);
  });

  test('Autodetecting settings works in converter mode', () {
    var det = new FirstOccurrenceSettingsDetector(
        fieldDelimiters: [',', ';'],
        textDelimiters: ['"', "'"],
        textEndDelimiters: ['"', "'"],
        eols: ['\r\n', '\n']);
    expect(
        aaBbCsvToListConverter.convert(csvSimpleStringsSingleRowComma,
            csvSettingsDetector: det, shouldParseNumbers: true),
        equals([simpleStringsSingleRow]));

    det = new FirstOccurrenceSettingsDetector(
        fieldDelimiters: [',', 'b'],
        textDelimiters: ["'", '"'],
        textEndDelimiters: ['.', '"'],
        eols: ['\n']);
    expect(
        commaDoubleQuotCsvToListConverterParseNumbers.convert(csvSingleRowComma,
            csvSettingsDetector: det, shouldParseNumbers: false),
        equals([singleRowAllText]));

    det = new FirstOccurrenceSettingsDetector(
        fieldDelimiters: ['aa', '2'],
        textDelimiters: ['bb', '"'],
        textEndDelimiters: ['"', 'bb']);
    expect(
        commaDoubleQuotCsvToListConverter.convert(csvSingleRowAaBb,
            csvSettingsDetector: det, shouldParseNumbers: true),
        equals([singleRow]));
  });

  test('Autodetects settings for a multiline csv string correctly', () {
    var det = new FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
    var converter = new CsvToListConverter(csvSettingsDetector: det);
    var eol = '\n';
    var csv =
        csvSingleRowComma + eol + csvSingleRowComma + eol + csvSingleRowComma;
    expect(converter.convert(csv), equals(multipleRows));

    det = new FirstOccurrenceSettingsDetector(
        eols: ['\r\n', '\n'],
        textDelimiters: ['""', "'"],
        textEndDelimiters: ['««', '!']);
    csv = autodetectCsv;
    expect(new CsvToListConverter(csvSettingsDetector: det).convert(csv),
        equals(autodetectRows));
  });
}
