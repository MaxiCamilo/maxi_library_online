import 'dart:convert';

import 'dart:typed_data';

// ignore: implementation_imports
import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';

class MapServerRequest with IRequest, ICustomSerialization {
  static const String requestFlag = 'HttpRequest';

  final List<int>? rawBinaryContent;
  final String? rawStringContent;
  @override
  final Map<String, String> headers;
  @override
  final int contentLength;
  @override
  final HttpMethodType methodType;

  @override
  final IHttpServer server;
  @override
  final Uri url;

  @override
  final Map<String, dynamic> valuesInRoute;

  @override
  bool get isWebSocket => methodType == HttpMethodType.webSocket;

  MapServerRequest._(
      {required this.rawBinaryContent, required this.rawStringContent, required this.headers, required this.contentLength, required this.methodType, required this.server, required this.url, required this.valuesInRoute});

  factory MapServerRequest.fromJson({required IHttpServer server, required String rawJson, bool checkFlag = true}) => MapServerRequest.fromMap(
        server: server,
        checkFlag: checkFlag,
        message: ConverterUtilities.interpretToObjectJson(text: rawJson),
      );

  factory MapServerRequest.fromMap({required IHttpServer server, required Map<String, dynamic> message, bool checkFlag = true}) {
    if (checkFlag && !(message.containsKey('\$type') && message['\$type'] == requestFlag)) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidValue,
        message: const Oration(message: 'The petition map must have the type flag'),
      );
    }

    final rawUrl = message.getRequiredValueWithSpecificType<String>('url');
    final url = volatile(
      detail: const Oration(message: 'The URL in the message is invalid'),
      function: () => Uri.parse(rawUrl),
    );

    final headers = message.getRequiredValueWithSpecificType<Map<String, dynamic>>('headers').map((x, y) => MapEntry(x, y.toString()));
    final rawMethodType = message.getRequiredValueWithSpecificType<int>('methodType');
    final methodType = volatile(
      detail: const Oration(message: 'The method type is invalid'),
      function: () => HttpMethodType.values[rawMethodType],
    );

    late final String? textContent;
    late final List<int>? byteContent;
    late final int length;

    final contentType = message.getRequiredValueWithSpecificType<String>('contentType');
    if (contentType == 'text') {
      byteContent = null;
      textContent = message.getRequiredValueWithSpecificType<String>('content');
      length = textContent.length;
    } else if (contentType == 'binary') {
      textContent = null;
      final rawBinaryContent = message.getRequiredValue('content');
      if (rawBinaryContent is String) {
        byteContent = volatile(detail: const Oration(message: 'The binary content of the request is not a base64 valid '), function: () => base64.decode(rawBinaryContent));
      } else if (rawBinaryContent is List<int>) {
        byteContent = rawBinaryContent;
      } else {
        throw NegativeResult(
          identifier: NegativeResultCodes.invalidValue,
          message: const Oration(message: 'The binary content of the request is not valid'),
        );
      }
      length = byteContent!.length;
    } else {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidValue,
        message: Oration(
          message: 'Content type "%1" is not valid',
          textParts: [contentType],
        ),
      );
    }

    return MapServerRequest._(
      rawBinaryContent: byteContent,
      rawStringContent: textContent,
      headers: headers,
      contentLength: length,
      methodType: methodType,
      server: server,
      url: url,
      valuesInRoute: Map.from(url.queryParameters),
    );
  }

  @override
  Stream<List<int>> get readContent async* {
    if (rawBinaryContent == null) {
      yield base64.decode(rawStringContent!);
    } else {
      yield rawBinaryContent!;
    }
  }

  @override
  Future<Uint8List> readContentAsBinary({int? maxSize}) async {
    late final Uint8List content;
    if (rawBinaryContent == null) {
      content = base64.decode(rawStringContent!);
    } else {
      content = Uint8List.fromList(rawBinaryContent!);
    }

    if (maxSize != null && content.length > maxSize) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidValue,
        message: Oration(message: 'The content of the request is too large (Accepts up to %1 bytes, but %2 bytes were trying to be sent)', textParts: [maxSize, contentLength]),
      );
    }

    return content;
  }

  @override
  Future<String> readContentAsString({int? maxSize, Encoding? encoding}) async {
    late final String content;
    if (rawStringContent == null) {
      content = base64.encode(rawBinaryContent!);
    } else {
      content = rawStringContent!;
    }

    if (maxSize != null && content.length > maxSize) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidValue,
        message: Oration(message: 'The content of the request is too large (Accepts up to %1 bytes, but %2 bytes were trying to be sent)', textParts: [maxSize, contentLength]),
      );
    }

    return content;
  }

  @override
  Map<String, dynamic> serialize() {
    final map = <String, dynamic>{};

    map['\$type'] = requestFlag;
    map['methodType'] = methodType.index;
    map['url'] = url.toString();
    map['headers'] = headers;

    if (rawStringContent == null) {
      map['contentType'] = 'binary';
      map['content'] = base64.encode(rawBinaryContent!);
    } else {
      map['contentType'] = 'text';
      map['content'] = rawStringContent!;
    }

    return map;
  }
}
