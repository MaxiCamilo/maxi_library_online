import 'dart:convert';

import 'package:maxi_library/maxi_library.dart';

class NegativeResultHttp extends NegativeResult {
  final int httpErrorCode;
  final dynamic content;

  NegativeResultHttp({
    required super.identifier,
    required super.message,
    required this.httpErrorCode,
    super.whenWasIt,
    super.cause,
    this.content,
  });

  String generateJson() {
    final map = <String, dynamic>{};

    map['isCorrect'] = false;
    map['message'] = message;
    map['errorType'] = identifier.name;
    map['whenWasIt'] = ConverterUtilities.toInt(value: whenWasIt);

    if (content != null) {
      map['content'] = content;
    }

    return json.encode(map);
  }
}
