import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:maxi_library_online/src/http_server/response_http.dart';
import 'package:maxi_library_online/src/http_server/interfaces/iweb_socket.dart';
import 'package:maxi_library_online/src/shelf/web_socket_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

class HttpServerShelf extends HttpServerImplementationWithFinalExecution<Response> {
  final String appName;
  final double appVersion;

  final Object address;
  final int port;
  final SecurityContext? securityContext;
  final bool addAccessControlAllowOrigin;
  final String accessControlAllowOrigin;

  late HttpServer _server;

  final _webSocketList = <IChannel>[];

  HttpServerShelf({
    required super.routes,
    super.routeNotFound,
    required this.appName,
    required this.appVersion,
    required this.address,
    required this.port,
    required this.securityContext,
    this.addAccessControlAllowOrigin = true,
    this.accessControlAllowOrigin = '*',
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
    final routes = IHttpServer.getAllRouteByReflection(serverMiddleware: serverMiddleware, entityList: entityList);
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
  Future<void> closeServerImplementation({bool forced = false}) async {
    await _server.close(force: forced);
    await closeAllWebSockets();
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
            message: Oration(message: 'The serialization of the output from the called function failed with the following error: %1', textParts: [ex.toString()]),
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
            'message': Oration(message: 'The requested function has completed successfully').serialize(),
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
        } else if (ConverterUtilities.isPrimitive(e.runtimeType) != null) {
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

    if (addAccessControlAllowOrigin && !cabezal.containsKey('Access-Control-Allow-Origin')) {
      cabezal['Access-Control-Allow-Origin'] = accessControlAllowOrigin;
      cabezal['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
      cabezal['Access-Control-Allow-Headers'] = 'Origin, Content-Type';
    }

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
  Future createWebSocketForPipe({required IRequest request, required IMasterChannel master, Iterable<String>? protocols, Iterable<String>? allowedOrigins, Duration? pingInterval}) {
    return createWebSocket(
      request: request,
      allowedOrigins: allowedOrigins,
      pingInterval: pingInterval,
      protocols: protocols,
      onConnection: (ws) async {
        try {
          if (master is StartableFunctionality) {
            await (master as StartableFunctionality).initialize();
          }

          final slave = master.createSlave();

          _webSocketList.add(ws);

          slave.receiver.listen(
            (x) => ws.addIfActive(x),
            onError: (x, y) => ws.addErrorIfActive(x, y),
            onDone: () => ws.close(),
          );
          ws.receiver.listen(
            (x) => slave.addIfActive(x),
            onError: (x, y) => slave.addErrorIfActive(x, y),
            onDone: () {
              slave.close();
              _webSocketList.remove(ws);
            },
          );

/*
          if (pipe is BroadcastPipe) {
            pipe.connectPipe(ws);
          } else {
            pipe.joinCrossPipe(pipe: ws);
          }
          */

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
          final rn = NegativeResult.searchNegativity(item: ex, actionDescription: Oration(message: 'Creating a pipe connection'));
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
        ws.receiver.listen(sink.add, onError: sink.addError, onDone: () {
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

  @override
  Future<void> closeAllWebSockets() async {
    _webSocketList.iterar((x) => x.close());
    _webSocketList.clear();
  }
}
