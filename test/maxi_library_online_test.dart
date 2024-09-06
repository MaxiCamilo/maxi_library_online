import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Test url', () {
      final urlText = 'http://maxi.com/hola/susana?esBueno=21';
      final url = Uri.parse(urlText);
      print(url);
    });
  });
}
