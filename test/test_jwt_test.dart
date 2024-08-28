@Timeout(Duration(minutes: 30))
library;

import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

const secretKey = 'your_secret_key_here'; // Cambia esto por una clave secreta segura

void main() async {
  final app = Router();

  // Endpoint para registrarse
  app.post('/register', (Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    // Aquí deberías crear el usuario en la base de datos

    final token = _generateJWT(data['username']);
    return Response.ok(jsonEncode({'token': token}), headers: {'Content-Type': 'application/json'});
  });

  // Endpoint para iniciar sesión
  app.post('/login', (Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    // Verificar credenciales del usuario contra la base de datos

    final token = _generateJWT(data['username']);
    return Response.ok(jsonEncode({'token': token}), headers: {'Content-Type': 'application/json'});
  });

  // Endpoint protegido
  app.get('/protected', _authenticate((Request request) {
    return Response.ok('This is a protected resource!');
  }));

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(app.call);

  final server = await shelf_io.serve(handler, 'localhost', 8080);
  print('Server listening on port ${server.port}');

  await Future.delayed(Duration(minutes: 15));
}

// Genera un JWT
String _generateJWT(String username) {
  final jwt = JWT(
    {
      'username': username,
      'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch,
    },
  );

  return jwt.sign(SecretKey(secretKey));
}

// Middleware de autenticación
Handler _authenticate(Handler handler) {
  return (Request request) async {
    final authHeader = request.headers['Authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(secretKey));

        // Puedes acceder a los datos del token con jwt.payload

        return handler(request);
      } catch (e) {
        return Response.forbidden('Invalid token: $e');
      }
    }

    return Response.forbidden('Unauthorized');
  };
}
