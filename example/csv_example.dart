import 'package:csv/csv.dart';

void main() {
  final input = [['name', 'age'], ['Alice', 30], ['Bob', 25]];
  final encoded = csv.encode(input);
  print('Encoded: $encoded');
  
  final decoded = csv.decode(encoded);
  print('Decoded: $decoded');
}
