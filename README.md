*Specify (at least a major) version when adding this project as dependency.  Whenever the API has incompatible changes
the major version changes!*

# Changes from version 3 to 4:
* no new functionality.
* adapted to dart2.  This library is no longer a codec!

# Changes from version 2 to 3:

* `parseNumbers` has been renamed to `shouldParseNumbers`
* `FirstOccurenceSettingsDetector` has been renamed to
  `FirstOccurrenceSettingsDetector`
* Speed improvements.


# Changes from version 3.0 to 3.1

* added option `delimitAllFields`
* fix issue #5 (endDelimiter was not always taken correctly from delimiter)

## Changes from version 3.1 to 3.1.1

* fix issue #10 (SDK version was overlay restrictive)

# csv

A dart csv to list converter.

If you have a `String` of all rows with RFC conform separators and delimiters,
simply convert them with:
```dart
List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(yourString);
```

To convert to a Csv string your values must be in a `List<List<dynamic>>`
representing a List of Rows where every Row is a List of values.
You can then convert with:
```dart
String csv = const ListToCsvConverter().convert(yourListOfLists);
```

The default (RFC conform) configuration is:
* _,_ as field separator
* _"_ as text delimiter and
* _\r\n_ as eol.

See below if you need other settings, or want to autodetect them.

This converter may be used as transformer for
streams:

```dart
final stream = new Stream.fromIterable([['a', 'b'], [1, 2]]);
final csvRowStream = stream.transform(new ListToCsvConverter());
```

Or the decoder side:

```dart
final input = new File('a/csv/file.txt').openRead();
final fields = await input.transform(utf8.decoder).transform(new CsvToListConverter()).toList();
```

The converter is highly customizable and even allows multiple characters as
delimiters or separators.

    
![Build Status](https://travis-ci.org/close2/csv.svg?branch=master)


### The decoder

Every csv row is converted to a list of values.  Unquoted strings looking like
numbers (integers and doubles) are by default converted to `int`s or `double`s.

### The encoder

The input must be a `List` of `List`s.  Every inner list is converted to one
output csv row.  The string representation of values is obtained by calling
`toString`.

This converter follows the rules of
[rfc4180](https://tools.ietf.org/html/rfc4180).

This means that text fields containing any delimiter or an eol are quoted.

The default configuration is:

* _,_ as field separator
* _"_ as text delimiter and
* _\r\n_ as eol.

This parser will accept eol and text-delimiters inside unquoted text and
not throw an error.

In addition this converter supports multiple characters for all delimiters
and eol.  Also the start text delimiter and end text delimiter may be
different.  This means the following text can be parsed:
`«abc«d»*|*«xy»»z»*|*123`  
And (if configured correctly) will return `['abc«d', 'xy»z', 123]`


## Usage

### Encoder `List<List>` → `String`

If the default values are fine, simply instantiate `ListToCsvConverter` and
call `convert`:

```dart
final res = const ListToCsvConverter().convert([[',b', 3.1, 42], ['n\n']]);
assert(res == '",b",3.1,42\r\n"n\n"');
```

Consider using the `returnString = false` option to work around a performance bug.

 
There are 2 interesting things to note:

* Not all rows have to be the same length.
* The default eol is `'\r\n'` and `'\n'` is also quoted.  The appearance of only
 one character is enough for the string to be quoted.

The converter takes the following configurations either in the constructor or
the `convert` function:

* `fieldDelimiter`: the separator between fields.  By default `','` but another
 common value is `';'`.
* `textDelimiter`: the quotation string.  By default `'"'`.
* `textEndDelimiter`: the end quotation string.  By default equals
 `textDelimiter`.  The string used to end a quoted string.
* `eol`: The new line string.  By default `'\r\n'`.  Another common value: `'\n'`

*All configuration values may be multiple characters!:*

```dart
const conv = const ListToCsvConverter(fieldDelimiter: '|*|',
                                      textDelimiter: '<<',
                                      textEndDelimiter: '>>',
                                      eol: '**\n');
final res = conv.convert([['a','>'], ['<<', '>>'], [1, 2]]);
assert(res == 'a|*|<<>>>**\n<<<<>>|*|<<>>>>>>**\n1|*|2');

final res2 = const ListToCsvConverter()
    .convert([['a','>'], ['<<', '>>'], [1, 2]],
             fieldDelimiter: '|*|',
             textDelimiter: '<<',
             textEndDelimiter: '>>',
             eol: '**\n');
assert(res == res2);
```

Note that:

* `'>'` is quoted
* `'<<'` is quoted as well, but because it is "only" a start text delimiter
 it is *not* doubled. (See rule 7. below).
* `'>>'` is quoted.  *Only the end-quote string is doubled!*


### Decoder `String` → `List<List>`

If the default values are fine, simply instantiate `CsvToListConverter` and
call `convert`:

```dart
final res = const CsvToListConverter().convert('",b",3.1,42\r\n"n\n"');
assert(res.toString() == [[',b', 3.1, 42], ['n\n']].toString());
```

Again please note that depending on the input not all rows have the same number
of values.

The `CsvToListConverter` takes the same arguments as the `ListToCsvConverter`
plus

* `shouldParseNumbers`: by default true.  If you want the output to be `String`s only
 set this to false.
* `allowInvalid`: by default *true*.  The converter will by default never throw
 an exception.  Even if `fieldDelimiter`, `textDelimiter`,... don't make sense
 or the csv-String is invalid.  This may for instance happen if the csv-String
 ends with a quoted String without the end-quote (`textEndDelimiter`) string.
* `csvSettingsDetector`: must be an object which extends from
 `CsvSettingsDetector`.  There implementation simply selects the first occurrence
  of a list of possible values as value.
  
  ```dart
  var d = new FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n'],
                                              textDelimiters: ['"', "'"]);
  
  new CsvToListConverter(csvSettingsDetector: d);
  ```
    
In this case `eol` will either be `'\r\n'` or `'\n'` depending on which of
those 2 comes first in the csv string.  Note that the
`FirstOccurrenceSettingsDetector` doesn't parse the csv string!  For instance
if eol should be `'\r\n'` but there is a field with a correctly quoted `'\n'`
in the first row, `'\n'` is used instead.

If you csv String contains a (simple) header row, or all eols are equal this
is good enough.

Feel free to submit something more intelligent.


To check your configuration values there is `CsvToListConverter.verifySettings`
and `verifyCurrentSettings`.  Both return an empty list if all settings are valid,
or a list of errors.  If the optional `throwError` is true an error is thrown in
case the settings are invalid.

All settings must be set, i.e. not be null, and delimiters, separators and eols must
be distinguishable, i.e. they may not be the start of another settings.


## CSV rules -- copied from RFC4180 Chapter 2

Ad rule 3: removed as it is not relevant for this converter.

1. Each record is located on a separate line, delimited by a line break
   (CRLF).  For example:
    aaa,bbb,ccc CRLF
    zzz,yyy,xxx CRLF

2. The last record in the file may or may not have an ending line break.
   For example:
    `aaa,bbb,ccc CRLF`
    zzz,yyy,xxx

3. ... (Header-lines)

4. Within the header and each record, there may be one or more fields,
   separated by commas.  Each line should contain the same number of
   fields throughout the file.  Spaces are considered part of a field and
   should not be ignored.  The last field in the record must not be
   followed by a comma.  For example:

    aaa,bbb,ccc

5. Each field may or may not be enclosed in double quotes (however some
   programs, such as Microsoft Excel, do not use double quotes at all).
   If fields are not enclosed with double quotes, then double quotes may
   not appear inside the fields.  For example:

    "aaa","bbb","ccc" CRLF
    zzz,yyy,xxx

6. Fields containing line breaks (CRLF), double quotes, and commas should
   be enclosed in double-quotes.  For example:

    "aaa","b CRLF
    bb","ccc" CRLF
    zzz,yyy,xxx

7. If double-quotes are used to enclose fields, then a double-quote
   appearing inside a field must be escaped by preceding it with another
   double quote.  For example:

    "aaa","b""bb","ccc"



