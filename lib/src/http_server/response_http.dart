class ResponseHttp {
  final int idState;
  final dynamic content;
  final String contentType;
  final Map<String, Object> header;

  const ResponseHttp({required this.idState, required this.content, required this.contentType, required this.header});
}
