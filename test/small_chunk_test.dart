
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:test/test.dart';

void main() {
  test('Small chunk delimiter detection', () async {
    final input = 'sep=;\r\na;b;c';
    // Split into tiny chunks to force edge cases
    final chunks = input.split('').map((c) => c).toList();
    
    final controller = StreamController<String>();
    final stream = controller.stream.transform(csv.decoder);
    
    final resultFuture = stream.toList();
    
    for (var chunk in chunks) {
      controller.add(chunk);
      await Future.delayed(Duration(milliseconds: 1));
    }
    await controller.close();
    
    final result = (await resultFuture).expand((i) => i).toList();
    expect(result, [['a', 'b', 'c']]);
  });
  
  test('Small chunk normal CSV', () async {
    final input = 'a,b,c\n1,2,3';
    // Split into tiny chunks
    final chunks = input.split('').map((c) => c).toList();
    
    final controller = StreamController<String>();
    final stream = controller.stream.transform(csv.decoder);
    
    final resultFuture = stream.toList();
    
    for (var chunk in chunks) {
      controller.add(chunk);
    }
    await controller.close();
    
    final result = (await resultFuture).expand((i) => i).toList();
    expect(result, [['a', 'b', 'c'], ['1', '2', '3']]);
  });
}
