@Timeout(Duration(minutes: 30))
library;

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:test/test.dart';

import 'test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {
      ReflectionManager.defineAlbums = [testReflectors];
      ReflectionManager.defineAsTheMainReflector();
    });

    test('Build server', () async {
      /*
      final securityContext = SecurityContext()
        ..useCertificateChain('./cert.pem') // Ruta a tu certificado
        ..usePrivateKey('./key.pem'); // Ruta a tu clave privada
        */

      final server = HttpServerShelf.fromReflection(
        appName: 'Test',
        appVersion: 0.420,
        address: '127.0.0.1',
        port: 2121,
        //securityContext: securityContext,
      );

      await server.startServer();

      /*
      Future.delayed(Duration(seconds: 15)).whenComplete(() async {
        await server.closeServer(forced: true);
      });
      */

      await server.waitFinish();

      //await Future.delayed(Duration(seconds: 30));
    });
  });
}
