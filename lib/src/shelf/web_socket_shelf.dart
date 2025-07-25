import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/error_handling/negative_result_http.dart';
import 'package:maxi_library_online/src/http_server/interfaces/iweb_socket.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

class WebSocketShelf with IDisposable, IChannel, IWebSocket {
  static Future<Response> makeWebSocket({
    required Request request,
    required Function(IWebSocket) onConnect,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  }) async {
    if (request.method != "GET") {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: Oration(message: 'Creating a websocket channel failed: Websockets require the method to be "get"'),
      );
    }
    var connectionHeader = request.headers[HttpHeaders.connectionHeader];
    if (connectionHeader == null) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: Oration(message: 'Creating a websocket channel failed: "connection" head is required'),
      );
    }

    bool isUpgrade = false;
    for (var value in connectionHeader.split(';')) {
      if (value.toLowerCase() == "upgrade") {
        isUpgrade = true;
        break;
      }
    }
    if (!isUpgrade) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: Oration(message: 'Creating a websocket channel failed: The "connection" header must be "upgrade", to create a web socket'),
      );
    }
    final upgrade = request.headers[HttpHeaders.upgradeHeader];
    if (upgrade == null || upgrade.toLowerCase() != "websocket") {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: Oration(message: 'Creating a websocket channel failed: The "upgrade" head is required and must be defined as "websocket"'),
      );
    }
    final version = request.headers["Sec-WebSocket-Version"];
    if (version == null || version != "13") {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: Oration(message: 'Creating a websocket channel failed: The "Sec-WebSocket-Version" head is required and must be defined as "13"'),
      );
    }
    final key = request.headers["Sec-WebSocket-Key"];
    if (key == null) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: Oration(message: 'Creating a websocket channel failed: The "Sec-WebSocket-Key" head is required'),
      );
    }

    return webSocketHandler(
      (x) => _onConnection(webSocket: x, streamReturner: onConnect),
      protocols: protocols,
      allowedOrigins: allowedOrigins,
      pingInterval: pingInterval,
    )(request);
  }

  static _onConnection({required dynamic webSocket, required Function(IWebSocket) streamReturner}) {
    final newSocket = WebSocketShelf._(webSocket: webSocket);
    streamReturner(newSocket);
  }

  final dynamic _webSocket;
  late final StreamController _controllerReceiver;

  WebSocketShelf._({required dynamic webSocket}) : _webSocket = webSocket {
    _controllerReceiver = StreamController.broadcast();
    _webSocket.stream.listen(
      (message) {
        _controllerReceiver.add(message);
      },
      onDone: close,
    );
  }

  @override
  void add(event) {
    try {
      _webSocket.sink.add(_sanitizeEvent(event));
    } catch (ex) {
      addError(NegativeResult(
        identifier: NegativeResultCodes.wrongType,
        message: Oration(message: 'An error occurred while serializing a message for client transmission. The object of type %1 cannot be serialized', textParts: [event.runtimeType]),
      ));
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    final nr = NegativeResult.searchNegativity(item: error, actionDescription: Oration(message: 'Request web'));
    add(json.encode(nr.serialize()));
  }

  @override
  Future addStream(Stream stream) async {
    await for (final item in stream) {
      if (isActive) {
        add(item);
      } else {
        break;
      }
    }
  }

  @override
  Future close() async {
    dispose();
  }

  @override
  Future get done => onDispose;

  @override
  bool get isActive => !wasDiscarded;

  @override
  Stream get receiver => _controllerReceiver.stream;

  _sanitizeEvent(content) {
    if (content == null) {
      return null;
    }

    if (content is String || content is List<int>) {
      return content;
    }

    if (content is Map<String, dynamic>) {
      return json.encode(content);
    } else if (content is num || content is bool) {
      return content.toString();
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
      return jsonList.toString();
    } else if (content is NegativeResultHttp) {
      return json.encode(content.serialize());
    } else if (content is NegativeResult) {
      return json.encode(content.serialize());
    } else if (content is ICustomSerialization) {
      return _sanitizeEvent(content.serialize());
    }

    final reflDio = ReflectionManager.getReflectionEntity(content.runtimeType);
    return reflDio.serializeToJson(value: content, setTypeValue: true);
  }

  @override
  void performObjectDiscard() {
    _controllerReceiver.close();
    containErrorLogAsync(detail: const Oration(message: 'Dispose web socket sink'), function: () => _webSocket.sink.close());
  }
}
