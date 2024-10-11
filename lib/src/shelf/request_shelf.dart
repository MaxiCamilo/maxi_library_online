import 'dart:convert';
import 'dart:io';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_server/irequest.dart';
import 'package:maxi_library_online/src/http_server/server/http_server_implementation.dart';
import 'package:shelf/shelf.dart';

class RequestShelf with IRequest {
  @override
  final HttpServerImplementation server;

  late final Request request;

  @override
  late final HttpMethodType methodType;

  @override
  late final Map<String, dynamic> valuesInRoute;

  RequestShelf({required this.request, required this.server}) {
    valuesInRoute = Map.from(request.url.queryParameters);
    methodType = switch (request.method.toLowerCase()) {
      'get' => HttpMethodType.getMethod,
      'post' => HttpMethodType.postMethod,
      'put' => HttpMethodType.putMethod,
      'delete' => HttpMethodType.deleteMethod,
      _ => throw NegativeResult(
          identifier: NegativeResultCodes.invalidFunctionality,
          message: tr('Method %1 has no use on the server', [request.method]),
        )
    };
  }

  @override
  final Map<String, dynamic> businessFragments = <String, dynamic>{};

  @override
  int get contentLength => request.contentLength ?? 0;

  @override
  Uri get url => request.url;

  @override
  Map<String, String> get headers => request.headers;

  @override
  Stream<List<int>> get readContent => request.read();

  @override
  Future<String> readContentAsString([Encoding? encoding]) => request.readAsString(encoding);

  @override
  bool get isWebSocket {
    return methodType == HttpMethodType.getMethod && (request.headers[HttpHeaders.upgradeHeader] ?? '').toLowerCase() == 'websocket';
  }
}
