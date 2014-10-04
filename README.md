csv
===

A dart csv to list codec / converter


The encoder
===========

Parses a csv string into a List of rows.  Each row is represented by a
List.

This converter follows the rules of
[rfc4180](http://tools.ietf.org/html/rfc4180).

The default configuration is:
* _,_ as field separator
* _"_ as text delimiter and
* _\r\n_ as eol.


This parser will accept eol and text-delimiters inside unquoted text and
not throw an error.

In addition this converter supports multiple characters for all delimiters
and eol.  Also the start text delimiter and end text delimiter may be
different.  This means the following text can be parsed:
«abc«d»*|*«xy»»z»*|*123
And (if configured correctly) will return ['abc«d', 'xy»z', 123]



CSV rules -- copied from RFC4180 Chapter 2
==========================================

Ad rule 3: removed as it is not relevant for this converter.

1. Each record is located on a separate line, delimited by a line break
   (CRLF).  For example:
    aaa,bbb,ccc CRLF
    zzz,yyy,xxx CRLF

2. The last record in the file may or may not have an ending line break.
   For example:
    aaa,bbb,ccc CRLF
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



[![Build Status](https://drone.io/github.com/close2/csv/status.png)](https://drone.io/github.com/close2/csv/latest)