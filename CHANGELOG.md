# 8.0.0
Fix stream nesting issue (#77): `stream.transform(csv.decoder).toList()` now
correctly returns `List<List<dynamic>>` instead of `List<List<List<dynamic>>>`.

**Breaking changes:**
- `CsvCodec` has been renamed to `Csv`. A deprecated `CsvCodec` typedef is
  provided for migration.
- `Csv` does not extend `dart:convert`'s `Codec`. Use `asCodec()` if you
  need a `Codec` (e.g., for `.fuse()`).
- `CsvDecoder` is now a `StreamTransformerBase<String, List<dynamic>>` instead of
  a `Converter<String, List<List<dynamic>>>`. Each stream event is a single row.
- `CsvEncoder` is now a `StreamTransformerBase<List<dynamic>, String>` instead of
  a `Converter<List<List<dynamic>>, String>`. Each stream event is a single row.
- `csv.decoder.fuse(...)` → use `csv.asCodec().decoder.fuse(...)` instead.

See the "The Codec Problem" section in the README for a detailed explanation.

# 7.2.0
Document CsvRow map-like access and necessary casts.
Add decodeWithHeaders() helper function.

# 7.1.0
Implement dynamic typing for CSV.

# 7.0.0
Complete rewrite of the library, now compatible with `dart:convert`.
Automatic delimiter detection and BOM support.
Optimized for performance and memory usage.
If you need compatibility with the older API, please continue using version 6.

# 6.0.0
If inside an unquoted string, text-delimiters are ignored instead of swallowed.  
This (partially?) fixes issue #70.  
Example: `"A B", "C, D"` will now produce `[["A B",' "C',' D"']]` instead of `[["A B",' C',' D']]`.

# 5.1.1
Fix warnings.  (Thanks https://github.com/thumbert for the bug report)

# 5.1.0

Implement feature request #29. It is now possible to specify a value for empty fields (CSV to List) and
a value for `null` (List to CSV).

# 5.0.2

fix bug #61 "Unexpected Error: The text end delimiter (") for the last field is missing."  
thanks https://github.com/liam7800

Improve nullsafety code.

# 5.0.1

fix bug #26 "A value of type 'dynamic' can't be assigned to a variable of type 'String'."  
thanks https://github.com/lil5

# 5.0.0

nullsafety
updating dependencies to released nullsafety version
Removing unnecessary const and new keywords

Thanks to: https://github.com/arnaudelub

# 5.0.0-nullsafety.0

nullsafety  
Thanks to: https://github.com/darwingr

# 4.1.0

Add `returnString` option to work around a major performance bug.  
Thanks: @boukeversteegh

# 4.0.3

Remove codec documentation in README

# 4.0.2

Fix analysis errors. No new functionality. No bug fix.

# 4.0.1

update dependencies for dart sdk 2.1
