@Timeout(Duration(minutes: 30))
library;

import 'dart:async';

import 'package:maxi_library/maxi_library.dart';
import 'package:test/test.dart';

Stream<int> count() async* {
  for (int i = 0; i < 20; i++) {
    yield i;
    if (i == 10) {
      throw 'jejejeje';
    }
  }
}

void main() {
  group('Reflection test', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('jejeje', () async {
      final com = Completer();
      final sub = count().listen(
        (x) => print('Num $x'),
        onError: (x) => print('Auch! $x'),
        onDone: () {
          print('bye!');
          com.complete();
        },
      );

      await com.future;
    });

    test('Generate file reflect', () {
      ReflectorGenerator(directories: ['test'], fileCreationPlace: '${DirectoryUtilities.prefixRouteLocal}/test', albumName: 'Test').build();
    });
  });
}
