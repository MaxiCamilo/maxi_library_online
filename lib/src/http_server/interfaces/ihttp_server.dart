import 'dart:convert';
import 'dart:typed_data';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';

mixin IHttpServer {
  bool get isActive;
  Future<void> waitFinish();
  Future<void> startServer();
  Future<void> closeServer({bool forced = false});
  Future<void> closeAllWebSockets();

  static List<FunctionalRoute> getAllRouteByReflection({required List<IHttpMiddleware> serverMiddleware, List<ITypeEntityReflection>? entityList}) {
    final routes = <FunctionalRoute>[];

    for (final reflectedClass in entityList ?? ReflectionManager.getEntities()) {
      for (final method in reflectedClass.methods) {
        final route = method.annotations.selectByType<HttpRequestMethod>();
        if (route == null) {
          continue;
        }

        final newMethod = FunctionalRoute.fromReflection(serverMiddleware: serverMiddleware, method: method, parent: reflectedClass);
        routes.add(newMethod);
      }
    }

    if (routes.isEmpty) {
      throw NegativeResult(
        identifier: NegativeResultCodes.contextInvalidFunctionality,
        message: Oration(message: 'There are no reflected methods for the http server'),
      );
    }

    return routes;
  }

  static String formatContent(dynamic content) {
    if (content == null) {
      return json.encode({
        'message': Oration(message: 'The requested function has completed successfully').serialize(),
        'whenWasIt': DateTime.now().millisecondsSinceEpoch,
      });
    }

    if (content is String) {
      return content;
    } else if (content is Map<String, dynamic>) {
      return json.encode(content);
    } else if (content is num || content is bool) {
      return content.toString();
    } else if (content is Uint8List) {
      return base64.encode(content);
    } else if (content is List) {
      final jsonList = StringBuffer('[');
      final contentComado = TextUtilities.generateCommand(list: content.map((e) {
        if (e is Map<String, dynamic>) {
          return json.encode(e);
        } else if (ReflectionUtilities.isPrimitive(e.runtimeType) != null) {
          return e.toString();
        }
        final reflItem = ReflectionManager.getReflectionEntity(e.runtimeType);
        return reflItem.serializeToJson(value: e, setTypeValue: true);
      }));

      jsonList.write(contentComado);
      jsonList.write(']');
      return jsonList.toString();
    } else if (content is NegativeResult) {
      return json.encode(content.serialize());
    }

    if (content is ICustomSerialization) {
      return content.serialize();
    }

    final reflDio = ReflectionManager.getReflectionEntity(content.runtimeType);
    return reflDio.serializeToJson(value: content, setTypeValue: true);
  }
}
