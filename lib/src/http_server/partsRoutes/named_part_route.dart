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
        namedValues[name] = part.convertQuickly.toInt(propertyName: tr(name));
        break;
      case PrimitiesType.isDouble:
        namedValues[name] = part.convertQuickly.toDouble(propertyName: tr(name));
        break;
      case PrimitiesType.isNum:
        namedValues[name] = part.convertQuickly.toDouble(propertyName: tr(name));
        break;
      case PrimitiesType.isString:
        namedValues[name] = part;
        break;
      case PrimitiesType.isBoolean:
        namedValues[name] = part.convertQuickly.toBoolean(propertyName: tr(name));
        break;
      case PrimitiesType.isDateTime:
        namedValues[name] = part.convertQuickly.toDateTime(propertyName: tr(name));
        break;
      case PrimitiesType.isBinary:
        throw NegativeResult(identifier: NegativeResultCodes.implementationFailure, message: tr('¡Binary interpretation was not created!'));
    }
  }
}
