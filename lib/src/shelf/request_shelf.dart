import 'dart:convert';

import 'package:maxi_library_online/src/reflected_server/irequest.dart';
import 'package:shelf_plus/shelf_plus.dart';

class RequestShelf with IRequest {
  final Request request;

  @override
  final Map<String, dynamic> businessFragments = <String, dynamic>{};

  @override
  Map<String, dynamic> get valuesInRoute => <String, dynamic>{};

  RequestShelf({required this.request});

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
}
