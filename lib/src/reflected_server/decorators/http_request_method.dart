enum HttpRequestMethodType { postMethod, getMethod, deleteMethod, putMethod }

class HttpRequestMethod {
  final HttpRequestMethodType type;
  final String route;

  const HttpRequestMethod({required this.type, required this.route});
}
