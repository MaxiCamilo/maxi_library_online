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

/*
  Future<dynamic> createWebSocket({
    required Function(IBidirectionalStream) onConnection,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  });
  */
}
