import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  test('BOM is consumed when delimiter is set', () {
    final input = '\ufeffa,b,c';
    final decoder = CsvDecoder(fieldDelimiter: ','); // Delimiter explicitly set
    final result = decoder.convert(input);

    expect(result, [
      ['a', 'b', 'c'],
    ]);
    expect(result[0][0], isNot(startsWith('\ufeff')));
  });

  test('BOM is consumed when delimiter is NOT set (auto-detect)', () {
    final input = '\ufeffa,b,c';
    final decoder = CsvDecoder(); // Auto-detect
    final result = decoder.convert(input);

    expect(result, [
      ['a', 'b', 'c'],
    ]);
    expect(result[0][0], isNot(startsWith('\ufeff')));
  });
}
