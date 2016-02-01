part of csv_parser;

class EolNullError extends ArgumentError {
  static const String msg = 'The eol character must not be null';
  EolNullError() : super(msg);
}

class FieldDelimiterNullError extends ArgumentError {
  static const String msg = 'The field delimiter character must not be null';
  FieldDelimiterNullError() : super(msg);
}

class TextDelimiterNullError extends ArgumentError {
  static const String msg = 'The text delimiter character must not be null';
  TextDelimiterNullError() : super(msg);
}

class TextEndDelimiterNullError extends ArgumentError {
  static const String msg =
      'The text end delimiter character must not be null.';
  TextEndDelimiterNullError() : super(msg);
}

class SettingsValuesEqualError extends ArgumentError {
  final String argument1;
  final String argument2;
  final String value1;
  final String value2;

  SettingsValuesEqualError(
      String argument1, String val1, String argument2, String val2)
      : this.argument1 = argument1,
        this.argument2 = argument2,
        this.value1 = val1,
        this.value2 = val2,
        super('$argument1 ($val1) and $argument2 ($val2) must be different '
            '(and one must not be the start of the other)');
}
