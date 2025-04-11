import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_server/irequest.dart';
import 'package:maxi_library_online/src/http_server/server/http_server_implementation_with_final_execution.dart';
import 'package:shelf/shelf.dart';

class RequestShelf with IRequest {
  @override
  final HttpServerImplementationWithFinalExecution server;

  late final Request request;

  @override
  late final HttpMethodType methodType;

  @override
  late final Map<String, dynamic> valuesInRoute;

  RequestShelf({required this.request, required this.server}) {
    valuesInRoute = Map.from(request.url.queryParameters);

    if ((request.headers[HttpHeaders.upgradeHeader] ?? '').toLowerCase() == 'websocket') {
      methodType = HttpMethodType.webSocket;
    } else {
      methodType = switch (request.method.toLowerCase()) {
        'get' => HttpMethodType.getMethod,
        'post' => HttpMethodType.postMethod,
        'put' => HttpMethodType.putMethod,
        'delete' => HttpMethodType.deleteMethod,
        _ => throw NegativeResult(
            identifier: NegativeResultCodes.invalidFunctionality,
            message: Oration(message: 'Method %1 has no use on the server', textParts: [request.method]),
          )
      };
    }
  }

  //@override
  //final Map<String, dynamic> businessFragments = <String, dynamic>{};

  @override
  int get contentLength => request.contentLength ?? 0;

  @override
  Uri get url => request.url;

  @override
  Map<String, String> get headers => request.headers;

  @override
  Stream<List<int>> get readContent => request.read();

  @override
  Future<String> readContentAsString({int? maxSize, Encoding? encoding}) {
    if (maxSize != null) {
      if (request.contentLength != null && maxSize < request.contentLength!) {
        throw NegativeResult(
          identifier: NegativeResultCodes.invalidValue,
          message: Oration(message: 'The content of the request is too large (Accepts up to %1 bytes, but %2 bytes were trying to be sent)', textParts: [maxSize, request.contentLength]),
        );
      }
    }

    return request.readAsString(encoding);
  }

  @override
  bool get isWebSocket {
    return methodType == HttpMethodType.getMethod && (request.headers[HttpHeaders.upgradeHeader] ?? '').toLowerCase() == 'websocket';
  }

  @override
  Future<Uint8List> readContentAsBinary({int? maxSize}) async {
    if (contentLength == 0) {
      return Uint8List.fromList([]);
    }

    if (maxSize != null) {
      if (maxSize < request.contentLength!) {
        throw NegativeResult(
          identifier: NegativeResultCodes.invalidValue,
          message: Oration(message: 'The content of the request is too large (Accepts up to %1 bytes, but %2 bytes were trying to be sent)', textParts: [maxSize, request.contentLength]),
        );
      }
    }

    final buffer = <int>[];

    await for (final part in readContent) {
      buffer.addAll(part);
    }

    return Uint8List.fromList(buffer);
  }
}
