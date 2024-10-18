import 'dart:convert';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_server/server/http_server_implementation.dart';

enum HttpMethodType { postMethod, getMethod, deleteMethod, putMethod, anyMethod }

mixin IRequest {
  HttpMethodType get methodType;

  Map<String, String> get headers;

  Uri get url;

  int get contentLength;

  Stream<List<int>> get readContent;

  Future<String> readContentAsString({int? maxSize, Encoding? encoding});

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

/*
  Future<dynamic> createWebSocket({
    required Function(IBidirectionalStream) onConnection,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  });
  */
}
