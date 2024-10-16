import 'dart:convert';

import 'package:maxi_library_online/src/http_server/server/http_server_implementation.dart';

enum HttpMethodType { postMethod, getMethod, deleteMethod, putMethod }

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

/*
  Future<dynamic> createWebSocket({
    required Function(IBidirectionalStream) onConnection,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  });
  */
}
