import 'package:test/test.dart';
import 'package:csv/csv.dart';

void main() {
  test('decode parseHeaders to CsvRow map-like access', () {
    final fileContents = 'id,name\n1,Alice\n2,Bob';
    final codec = CsvCodec(parseHeaders: true);
    
    final rows = codec.decode(fileContents);
    expect(rows.length, 2);
    
    final row = rows[0] as CsvRow;
    
    // Test index access
    expect(row[0], '1');
    expect(row[1], 'Alice');
    
    // Test header map access
    expect(row['id'], '1');
    expect(row['name'], 'Alice');
  });

  test('decodeWithHeaders returns List<CsvRow>', () {
    final fileContents = 'id,name\n1,Alice\n2,Bob';
    
    final rows = csv.decodeWithHeaders(fileContents);
    expect(rows.length, 2);
    
    // Notice no casting required here!
    final row = rows[0];
    
    // Test index access
    expect(row[0], '1');
    expect(row[1], 'Alice');
    
    // Test header map access
    expect(row['id'], '1');
    expect(row['name'], 'Alice');
  });
}
