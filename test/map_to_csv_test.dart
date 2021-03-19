import 'package:test/test.dart';
import "package:csv/csv.dart";

void main() {
  var sb = new StringBuffer();

  tearDown(() {
    sb.clear();
  });

  group("MapToCsvConverter Tests", () {
    test("writes header row", () {
      var fieldNames = ["one", "two", "three"];
      var writer = new MapToCsvConverter(sb, fieldNames);
      writer.writeheader();

      expect(sb.toString(), equals("one,two,three${defaultEol}"));
    });

    test("writes regular row", () {
      var fieldNames = ["one", "two", "three"];
      var writer = new MapToCsvConverter(sb, fieldNames);

      var data = {"one": "this", "two": "thing", "three": "works"};
      writer.writerow(data);

      expect(sb.toString(), equals("this,thing,works${defaultEol}"));
    });

    test("writes multiple rows", () {
      var fieldNames = ["one", "two", "three"];
      var writer = new MapToCsvConverter(sb, fieldNames);

      var data = [
        {"one": "this", "two": "thing", "three": "works"},
        {"one": "second", "two": "works", "three": "too"}
      ];
      writer.writerows(data);

      expect(
          sb.toString(),
          equals("this,thing,works${defaultEol}"
              "second,works,too${defaultEol}"));
    });

    test("ignores when extra fields present in data", () {
      var fieldNames = ["one", "two", "three"];
      var writer = new MapToCsvConverter(sb, fieldNames,
          extrasAction: ExtrasActions.ignore);

      var data = {
        "one": "this",
        "two": "thing",
        "three": "works",
        "extra": "ignore"
      };
      writer.writerow(data);

      expect(sb.toString(), equals("this,thing,works${defaultEol}"));
    });

    test("raises exception when extra fields present in data", () {
      var fieldNames = ["one", "two", "three"];
      var writer = new MapToCsvConverter(sb, fieldNames,
          extrasAction: ExtrasActions.raise);

      var data = {
        "one": "this",
        "two": "thing",
        "three": "works",
        "extra": "raise error",
        "extra_two": "other",
      };

      var expectedMessage =
          'Map contains fields not in fieldNames: "extra,extra_two"';
      expect(() => writer.writerow(data),
          throwsA(predicate((e) => e.message == expectedMessage)));
    });

    test("can customize field delimiter", () {
      var fieldNames = ["one", "two", "three"];
      var writer = new MapToCsvConverter(sb, fieldNames, fieldDelimiter: "|");

      var data = [
        {"one": "this", "two": "thing", "three": "works"},
        {"one": "second", "two": "works", "three": "too"}
      ];
      writer.writerows(data);

      expect(
          sb.toString(),
          equals("this|thing|works${defaultEol}"
              "second|works|too${defaultEol}"));
    });

    test("can customize text delimiter", () {
      var fieldNames = ["one", "two", "three"];
      var writer = new MapToCsvConverter(sb, fieldNames, textDelimiter: "'");

      var data = [
        {"one": "that's", "two": "thing", "three": "works"},
      ];
      writer.writerows(data);

      expect(sb.toString(), equals("'that''s',thing,works${defaultEol}"));
    });

    test("can customize eol delimiter", () {
      var fieldNames = ["one", "two", "three"];
      var writer = new MapToCsvConverter(sb, fieldNames, eol: "***");

      var data = [
        {"one": "this", "two": "thing", "three": "works"},
      ];
      writer.writerows(data);

      expect(sb.toString(), equals("this,thing,works***"));
    });

    test("can customize text end delimiter", () {
      var fieldNames = ["one", "two", "three"];
      var writer =
          new MapToCsvConverter(sb, fieldNames, textEndDelimiter: "&");

      var data = [
        {"one": '"air quotes"', "two": "thing", "three": "works"},
      ];
      writer.writerows(data);

      expect(sb.toString(), equals('""air quotes"&,thing,works$defaultEol'));
    });
  });
}
