library test_data;

const List<dynamic> singleRow = const [
  1,
  'a',
  2,
  'aabb',
  'c\nd',
  3,
  'e",f',
  4,
  "g',h",
  5.6
];
const String csvSingleRowComma = '1,a,2,aabb,"c\nd",3,"e"",f",4,"g\',h",5.6';
const String csvSingleRowSemicolon = '1;a;2;aabb;"c\nd";3;"e"",f";4;g\',h;5.6';
const String csvSingleRowDotDoubleQuot =
    '1.a.2.aabb."c\nd".3."e"",f".4.g\',h."5.6"';
const String csvSingleRowDotSingleQuot =
    "1.a.2.aabb.'c\nd'.3.e\",f.4.'g'',h'.'5.6'";
const String csvSingleRowAaBb =
    '1aabbabbaa2aabbaabbbbbbaabbc\ndbbaa3aae",faa4aag\',haa5.6';

const String csvSingleRowComma_endQuotXY =
    '1,a,2,aabb,"c\ndXY,3,"e",fXY,4,"g\',hXY,5.6';
const String csvSingleRowSemicolon_endQuotXY =
    '1;a;2;aabb;"c\ndXY;3;"e",fXY;4;g\',h;5.6';
const String csvSingleRowDotDoubleQuot_endQuotXY =
    '1.a.2.aabb."c\ndXY.3."e",fXY.4.g\',h."5.6XY';
const String csvSingleRowDotSingleQuot_endQuotDouble =
    "1.a.2.aabb.'c\nd\".3.'e\"\",f\".4.'g',h\".'5.6\"";
const String csvSingleRowAaBbXy =
    '1aabbaXYaa2aabbaabbXYaabbc\ndXYaa3aae",faa4aag\',haa5.6';

const List<List> multipleRows = const [singleRow, singleRow, singleRow];

const String csvSimpleStringsSingleRowComma = 'a,b';
const List simpleStringsSingleRow = const ['a', 'b'];

const List singleRowAllText = const [
  '1',
  'a',
  '2',
  'aabb',
  'c\nd',
  '3',
  'e",f',
  '4',
  "g',h",
  '5.6'
];
const List singleRowNoDouble = const [
  1,
  'a',
  2,
  'aabb',
  'c\nd',
  3,
  'e",f',
  4,
  "g',h",
  '5.6'
];

const List<List> multipleRowsAllText = const [
  singleRowAllText,
  singleRowAllText,
  singleRowAllText
];
const List<List> multipleRowsNoDouble = const [
  singleRowNoDouble,
  singleRowNoDouble,
  singleRowNoDouble
];

// fieldDelimiter: ...*
// textDelimiter: ...#
// eol: ....
const String csvComplex_part1 = '...*...#a.';
const String csvComplex_part2 = '.';
const String csvComplex_part3 = '.*..';
const String csvComplex_part4 =
    '.#...#...#...*...*1.2...*.......#1.2...#...*...*...#...#...#...#...........*....';

const String csvComplex_ending1 = '...';
const String csvComplex_ending2 = '...#...#';

const List<String> csvComplex_parts = const [
  csvComplex_part1,
  csvComplex_part2,
  csvComplex_part3,
  csvComplex_part4
];
const List<String> csvComplex_parts_ending1 = const [
  csvComplex_part1,
  csvComplex_part2,
  csvComplex_part3,
  csvComplex_part4,
  csvComplex_ending1
];
const List<String> csvComplex_parts_ending2 = const [
  csvComplex_part1,
  csvComplex_part2,
  csvComplex_part3,
  csvComplex_part4,
  csvComplex_ending2
];

const String csvComplexRows = '$csvComplex_part1'
    '$csvComplex_part2'
    '$csvComplex_part3'
    '$csvComplex_part4';
const String csvComplexRows_ending1 = '$csvComplex_part1'
    '$csvComplex_part2'
    '$csvComplex_part3'
    '$csvComplex_part4'
    '$csvComplex_ending1';
const String csvComplexRows_ending2 = '$csvComplex_part1'
    '$csvComplex_part2'
    '$csvComplex_part3'
    '$csvComplex_part4'
    '$csvComplex_ending2';

const List<List> complexRows = const [
  const ['', 'a...*...#', '', 1.2, ''],
  const ['1.2', '', '...#'],
  const [''],
  const ['', '']
];

const List<List> complexRows_ending1 = const [
  const ['', 'a...*...#', '', 1.2, ''],
  const ['1.2', '', '...#'],
  const [''],
  const ['', ''],
  const ['...']
];
const List<List> complexRows_ending2 = const [
  const ['', 'a...*...#', '', 1.2, ''],
  const ['1.2', '', '...#'],
  const [''],
  const ['', ''],
  const ['']
];

// fieldDelimiter: ...*
// textDelimiter: ...#
// eol: .*.*
const String csvComplex2_part1 = '..*.*...*#a..*';
const String csvComplex2_part2 = '.*..*.';

const String csvComplex2Rows = '$csvComplex2_part1$csvComplex2_part2';
const List<String> csvComplex2_parts = const [
  csvComplex2_part1,
  csvComplex2_part2
];

const List<List> complexRows2 = const [
  const ['.'],
  const ['', '#a.'],
  const ['..*.']
];

// fieldDelimiter: ,
// textDelimiter: .,a,b,__
// eol: _xyz
const List<String> csvComplex3_parts = const [
  '.,a,b,_',
  'xy',
  'z.,a,b,_',
  '__',
  'xyz.,a,b,',
  '___xyz,.',
  ',a,b,_'
];

final csvComplex3Rows = csvComplex3_parts.join();

const List<List> complexRows3 = const [
  const ['.', 'a', 'b', ''],
  const ['_xyz'],
  const ['', '.', 'a', 'b', '_']
];

const List<String> autodetectCsv_parts = const [
  'ab',
  'c,2',
  ',\n"',
  '"3,«',
  '«,\'\r',
  '\n!,\'\n'
];

final String autodetectCsv = autodetectCsv_parts.join();

const List<List> autodetectRows = const [
  const ['abc', 2, ''],
  const ['3,', "'\r"],
  const ['!', "'"]
];
