import 'dart:convert';
import 'dart:typed_data';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';

mixin IRequest {
  HttpMethodType get methodType;

  Map<String, String> get headers;

  Uri get url;

  int get contentLength;

  Stream<List<int>> get readContent;

  Future<String> readContentAsString({int? maxSize, Encoding? encoding});
  Future<Uint8List> readContentAsBinary({int? maxSize});

  //Map<String, dynamic> get businessFragments;

  Map<String, dynamic> get valuesInRoute;

  Map<String, dynamic> get valuesInMiddleware;

  IHttpServer get server;

  bool get isWebSocket;

  void checkOnlyWebSocket() {
    if (!isWebSocket) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: Oration(message: 'This function only supports execution via WebSocket'),
      );
    }
  }

  int getNumberParameter({required String name, required int defaultValue}) {
    final rawValue = valuesInRoute[name];
    if (rawValue == null) {
      return defaultValue;
    }

    return ConverterUtilities.toInt(propertyName: Oration(message: name), value: rawValue);
  }

  int? getOptionalNumberParameter({required String name}) {
    final rawValue = valuesInRoute[name];
    if (rawValue == null) {
      return null;
    }

    return ConverterUtilities.toInt(propertyName: Oration(message: name), value: rawValue);
  }

  bool parameterExists({required String name}) {
    return valuesInRoute.containsKey(name);
  }

  String getStringParameter({required String name, required String defaultValue}) {
    final rawValue = valuesInRoute[name];
    if (rawValue == null) {
      return defaultValue;
    }

    return rawValue;
  }

  String getRequiredStringParameter({required String name}) {
    final rawValue = valuesInRoute[name];
    if (rawValue == null) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidFunctionality,
        message: Oration(
          message: 'Parameter %1 is required in the URL',
          textParts: [name],
        ),
      );
    }

    return rawValue;
  }

  Future<T> interpretJsonContent<T>({int? maxSize, Encoding? encoding, bool tryToCorrectNames = true}) async {
    final rawContent = await readContentAsString(encoding: encoding, maxSize: maxSize);

    return ReflectionManager.interpretJson<T>(rawText: rawContent, tryToCorrectNames: tryToCorrectNames);
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
