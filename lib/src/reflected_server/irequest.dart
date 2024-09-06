import 'dart:convert';

mixin IRequest {
  Map<String, String> get headers;

  Uri get url;

  int get contentLength;

  Stream<List<int>> get readContent;

  Future<String> readContentAsString([Encoding? encoding]);

  Map<String, dynamic> get businessFragments;

  Map<String, dynamic> get valuesInRoute;
}
