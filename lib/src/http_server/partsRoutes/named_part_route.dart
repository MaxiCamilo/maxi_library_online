import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_server/partsRoutes/ipart_route.dart';

class NamedPartRoute with IPartRoute {
  final String name;
  final PrimitiesType type;

  const NamedPartRoute({required this.name, required this.type});

  @override
  bool acceptPart({required String part}) {
    return true;
  }

  @override
  void addValue({required String part, required Map<String, dynamic> namedValues}) {
    switch (type) {
      case PrimitiesType.isInt:
        namedValues[name] = GeneralConverter(part).toInt(propertyName: AlreadyTranslatedText(message: name));
        break;
      case PrimitiesType.isDouble:
        namedValues[name] = GeneralConverter(part).toDouble(propertyName: AlreadyTranslatedText(message: name));
        break;
      case PrimitiesType.isNum:
        namedValues[name] = GeneralConverter(part).toDouble(propertyName: AlreadyTranslatedText(message: name));
        break;
      case PrimitiesType.isString:
        namedValues[name] = GeneralConverter(part);
        break;
      case PrimitiesType.isBoolean:
        namedValues[name] = GeneralConverter(part).toBoolean(propertyName: AlreadyTranslatedText(message: name));
        break;
      case PrimitiesType.isDateTime:
        namedValues[name] = GeneralConverter(part).toDateTime(propertyName: AlreadyTranslatedText(message: name));
        break;
      case PrimitiesType.isBinary:
        throw NegativeResult(identifier: NegativeResultCodes.implementationFailure, message: tr('¡Binary interpretation was not created!'));
    }
  }
}
