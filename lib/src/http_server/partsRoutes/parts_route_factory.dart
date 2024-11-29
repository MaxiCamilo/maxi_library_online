import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_server/partsRoutes/fixed_part_route.dart';
import 'package:maxi_library_online/src/http_server/partsRoutes/ipart_route.dart';
import 'package:maxi_library_online/src/http_server/partsRoutes/named_part_route.dart';

class PartsRouteFactory {
  final List<IPartRoute> parts;

  const PartsRouteFactory._({required this.parts});

  factory PartsRouteFactory.build({required String route}) {
    final rawParts = route.split('/');
    if (rawParts.last.isEmpty) {
      rawParts.removeLast();
    }

    if (rawParts.first == '') {
      rawParts.removeAt(0);
    }

    if (rawParts.isEmpty) {
      rawParts.add('');
    }

    final list = <IPartRoute>[];

    for (final raw in rawParts) {
      if (raw.startsWith('[') && raw.endsWith(']')) {
        list.add(NamedPartRoute(name: raw.substring(1, raw.length - 1), type: PrimitiesType.isString));
      } else if (raw.startsWith('{') && raw.endsWith('}')) {
        list.add(_createNamedPartRouteWithType(raw));
      } else {
        list.add(FixedPartRoute(name: raw));
      }
    }

    return PartsRouteFactory._(parts: list);
  }

  static IPartRoute _createNamedPartRouteWithType(String raw) {
    final withoutParentheses = raw.substring(1, raw.length - 1);
    final parts = withoutParentheses.split(':');
    if (parts.length == 1) {
      return NamedPartRoute(name: parts.first, type: PrimitiesType.isString);
    }

    final name = parts.first;
    final type = parts.last.toLowerCase();

    switch (type) {
      case 'int':
        return NamedPartRoute(name: name, type: PrimitiesType.isInt);
      case 'double':
      case 'num':
        return NamedPartRoute(name: name, type: PrimitiesType.isDouble);
      case 'bool':
      case 'boolean':
        return NamedPartRoute(name: name, type: PrimitiesType.isBoolean);
      case 'datetime':
      case 'date':
      case 'time':
        return NamedPartRoute(name: name, type: PrimitiesType.isDateTime);
      case 'string':
      case '':
      case 'text':
        return NamedPartRoute(name: name, type: PrimitiesType.isString);

      default:
        throw NegativeResult(
          identifier: NegativeResultCodes.invalidValue,
          message: tr('Type value %1 of %2 does not match any option (int,double,datetime,bool)', [type, name]),
        );
    }
  }
}
