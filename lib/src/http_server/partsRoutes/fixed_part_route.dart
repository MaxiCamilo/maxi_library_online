import 'package:maxi_library_online/src/http_server/partsRoutes/ipart_route.dart';

class FixedPartRoute with IPartRoute {
  final String name;

  late final String lowercaseName;

  FixedPartRoute({required this.name}) {
    lowercaseName = name.toLowerCase();
  }

  @override
  bool acceptPart({required String part}) {
    return part.toLowerCase() == lowercaseName;
  }

  @override
  void addValue({required String part,required Map<String, dynamic> namedValues}) {}
}
