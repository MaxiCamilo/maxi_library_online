@Timeout(Duration(minutes: 30))
library;



import 'package:maxi_library/maxi_library.dart';
import 'package:test/test.dart';



void main() {
  group('Reflection test', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Generate file reflect', ()async {
     await  ReflectorGenerator(directories: ['test'], fileCreationPlace: '${DirectoryUtilities.prefixRouteLocal}/test', albumName: 'Test').build();
    });
  });
}
