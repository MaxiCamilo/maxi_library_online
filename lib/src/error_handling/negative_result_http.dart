import 'dart:convert';

import 'package:maxi_library/maxi_library.dart';

class NegativeResultHttp extends NegativeResult {
  final int httpErrorCode;
  final dynamic content;

  NegativeResultHttp({
    required super.identifier,
    required super.message,
    required this.httpErrorCode,
    super.whenWas,
    super.cause,
    this.content,
  });

  String generateJson() {
    final map = <String, dynamic>{};

    map['isCorrect'] = false;
    map['message'] = message;
    map['errorType'] = identifier.name;
    map['whenWas'] = ConverterUtilities.toInt(value: whenWas);

    if (content != null) {
      map['content'] = content;
    }

    return json.encode(map);
  }
}
