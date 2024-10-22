import 'dart:convert';
import 'dart:typed_data';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_server/server/http_server_implementation.dart';

enum HttpMethodType { postMethod, getMethod, deleteMethod, putMethod, anyMethod, webSocket }

mixin IRequest {
  HttpMethodType get methodType;

  Map<String, String> get headers;

  Uri get url;

  int get contentLength;

  Stream<List<int>> get readContent;

  Future<String> readContentAsString({int? maxSize, Encoding? encoding});
  Future<Uint8List> readContentAsBinary({int? maxSize});

  Map<String, dynamic> get businessFragments;

  Map<String, dynamic> get valuesInRoute;

  HttpServerImplementation get server;

  bool get isWebSocket;

  void checkOnlyWebSocket() {
    if (!isWebSocket) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: tr('This function only supports execution via WebSocket'),
      );
    }
  }

  int getNumberParameter({required String name, required int defaultValue}) {
    final rawValue = valuesInRoute[name];
    if (rawValue == null) {
      return defaultValue;
    }

    return ConverterUtilities.toInt(propertyName: tr(name), value: rawValue);
  }

/*
  Future<dynamic> createWebSocket({
    required Function(IBidirectionalStream) onConnection,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  });
  */
}
