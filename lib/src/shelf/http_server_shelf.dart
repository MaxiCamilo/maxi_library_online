import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:maxi_library_online/src/error_handling/negative_result_http.dart';
import 'package:maxi_library_online/src/http_server/response_http.dart';
import 'package:maxi_library_online/src/http_server/server/functional_route.dart';
import 'package:maxi_library_online/src/http_server/server/http_server_implementation.dart';
import 'package:maxi_library_online/src/http_server/server/interfaces/iweb_socket.dart';
import 'package:maxi_library_online/src/shelf/web_socket_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

class HttpServerShelf extends HttpServerImplementation<Response> {
  final String appName;
  final double appVersion;

  final Object address;
  final int port;
  final SecurityContext? securityContext;

  late HttpServer _server;

  HttpServerShelf({
    required super.routes,
    super.routeNotFound,
    required this.appName,
    required this.appVersion,
    required this.address,
    required this.port,
    required this.securityContext,
  });

  factory HttpServerShelf.fromReflection({
    required String appName,
    required double appVersion,
    required Object address,
    required int port,
    List<IHttpMiddleware> serverMiddleware = const [],
    SecurityContext? securityContext,
    dynamic Function(IRequest)? routeNotFound,
    List<ITypeEntityReflection>? entityList,
  }) {
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
        message: tr('There are no reflected methods for the http server'),
      );
    }

    return HttpServerShelf(
      routes: routes,
      appName: appName,
      appVersion: appVersion,
      address: address,
      port: port,
      securityContext: securityContext,
    );
  }

  @override
  Future<void> startServerImplementation() async {
    _server = await serve(_callRequest, address, port, securityContext: securityContext);
  }

  Future<Response> _callRequest(Request rawRequest) {
    final request = RequestShelf(request: rawRequest, server: this);
    return processRequest(request: request);
  }

  @override
  Future<void> closeServerImplementation({bool forced = false}) {
    return _server.close(force: forced);
  }

  @override
  Response generateReturnPackage(value) {
    try {
      return _serializeResponse(content: value);
    } catch (ex) {
      return _serializeResponse(
          idState: 500,
          content: NegativeResult(
            identifier: NegativeResultCodes.implementationFailure,
            message: tr('The serialization of the output from the called function failed with the following error: %1', [ex.toString()]),
          ));
    }
  }

  @override
  bool shouldRetriggerException(ex) => ex is HijackException;

  Response _serializeResponse({required dynamic content, int idState = 200}) {
    if (content == null) {
      return _generateSanitizedResponse(
          idState: idState,
          content: json.encode({
            'message': tr('The requested function has completed successfully').serialize(),
            'whenWasIt': DateTime.now().millisecondsSinceEpoch,
          }));
    }
    if (content is ResponseHttp) {
      final cabezal = {'content-type': content.contentType, 'x-app-version': appName, 'x-app-name': appVersion};
      cabezal.addAll(content.header);
      return Response(
        content.idState,
        body: content.content,
        headers: cabezal,
      );
    } else if (content is Response) {
      return content;
    } else if (content is String) {
      return Response.ok(content);
    } else if (content is Map<String, dynamic>) {
      return _generateSanitizedResponse(content: json.encode(content), idState: idState);
    } else if (content is num || content is bool) {
      return Response.ok(content.toString());
    } else if (content is Uint8List) {
      return _generateSanitizedResponse(content: content, contentType: PetitionContentType.binary, idState: idState);
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
      return _generateSanitizedResponse(content: jsonList.toString(), idState: idState);
    } else if (content is NegativeResultHttp) {
      return _generateSanitizedResponse(content: json.encode(content.serialize()), idState: content.httpErrorCode);
    } else if (content is NegativeResult) {
      return _generateSanitizedResponse(content: json.encode(content.serialize()), idState: 400);
    }

    if (content is ICustomSerialization) {
      return content.serialize();
    }

    final reflDio = ReflectionManager.getReflectionEntity(content.runtimeType);
    return _generateSanitizedResponse(content: reflDio.serializeToJson(value: content, setTypeValue: true), idState: idState);
  }

  Response _generateSanitizedResponse({
    int idState = 200,
    dynamic content,
    String contentType = PetitionContentType.json,
    Map<String, String> extraHeader = const {},
  }) {
    final cabezal = {'content-type': contentType, 'x-app-version': appVersion.toString(), 'x-app-name': appName};

    for (final parte in extraHeader.entries) {
      cabezal[parte.key] = parte.value;
    }

    return Response(idState, body: content, headers: cabezal);
  }

  Future createWebSocket({
    required IRequest request,
    required Function(IWebSocket) onConnection,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  }) {
    final shelftRequest = (request as RequestShelf).request;
    return WebSocketShelf.makeWebSocket(
      onConnect: onConnection,
      request: shelftRequest,
      protocols: protocols,
      allowedOrigins: allowedOrigins,
      pingInterval: pingInterval,
    );
  }

  @override
  Future createWebSocketForPipe({required IRequest request, required IPipe pipe, Iterable<String>? protocols, Iterable<String>? allowedOrigins, Duration? pingInterval}) {
    return createWebSocket(
      request: request,
      allowedOrigins: allowedOrigins,
      pingInterval: pingInterval,
      protocols: protocols,
      onConnection: (ws) async {
        try {
          if (pipe is StartableFunctionality) {
            await (pipe as StartableFunctionality).initialize();
          }

          if (pipe is BroadcastPipe) {
            pipe.connectPipe(ws);
          } else {
            pipe.joinCrossPipe(pipe: ws);
          }

/*
          pipe.stream.listen((x) {
            ws.add(x);
          }, onError: ws.addError);

          ws.stream.listen((x) {
            pipe.add(x);
          }, onError: pipe.addError);

          ws.done.whenComplete(() => pipe.close());
          pipe.done.whenComplete(() => ws.close());
          */
        } catch (ex) {
          final rn = NegativeResult.searchNegativity(item: ex, actionDescription: tr('Creating a pipe connection'));
          ws.add(rn.serializeToJson());
          ws.close();
        }
      },
    );
  }

  @override
  Future createWebSocketForSink({required IRequest request, required StreamSink sink, Iterable<String>? protocols, Iterable<String>? allowedOrigins, Duration? pingInterval}) {
    return createWebSocket(
      request: request,
      allowedOrigins: allowedOrigins,
      pingInterval: pingInterval,
      protocols: protocols,
      onConnection: (ws) async {
        ws.stream.listen(sink.add, onError: sink.addError, onDone: () {
          sink.close();
        });

        sink.done.whenComplete(() {
          ws.close();
        });
      },
    );
  }

  @override
  Future createWebSocketForStream({required IRequest request, required Stream stream, Iterable<String>? protocols, Iterable<String>? allowedOrigins, Duration? pingInterval}) {
    return createWebSocket(
      request: request,
      allowedOrigins: allowedOrigins,
      pingInterval: pingInterval,
      protocols: protocols,
      onConnection: (ws) async {
        final subcription = stream.listen(
          ws.add,
          onError: ws.addError,
          onDone: () {
            ws.close();
          },
        );

        ws.done.whenComplete(() => subcription.cancel());
      },
    );
  }
}
