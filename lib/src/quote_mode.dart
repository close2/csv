/// Defines how fields are quoted in the CSV.
enum QuoteMode {
  /// Only quote fields when they contain a delimiter, newline, or quote character.
  necessary,

  /// Always quote all fields, regardless of their content.
  always,

  /// Only quote fields that are of type [String].
  /// Numbers, booleans, and nulls will remain unquoted.
  strings,
}
