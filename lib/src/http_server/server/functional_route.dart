import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:maxi_library_online/src/http_server/server/functional_router_invoker_reflected.dart';
import 'package:maxi_library_online/src/http_server/interfaces/ifunctional_route_invoker.dart';
import 'package:maxi_library_online/src/http_server/partsRoutes/ipart_route.dart';
import 'package:maxi_library_online/src/http_server/partsRoutes/parts_route_factory.dart';

class FunctionalRoute {
  final HttpMethodType type;
  final List<IPartRoute> routeGuide;
  final List<IHttpMiddleware> middleware;
  final IFunctionalRouteInvoker invoker;

  const FunctionalRoute({required this.type, required this.routeGuide, required this.invoker, required this.middleware});

  factory FunctionalRoute.fromReflection({required List<IHttpMiddleware> serverMiddleware, required IMethodReflection method, required ITypeClassReflection parent}) {
    final route = method.annotations.selectByType<HttpRequestMethod>();
    if (route == null) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidValue,
        message: tr('Method %1 of class %2 does not have a "HttpRequestMethod" decorator', [method.name, parent.name]),
      );
    }

    final bufferRoute = StringBuffer();
    final classRoute = parent.annotations.selectByType<HttpRequestClass>();
    if (classRoute != null) {
      bufferRoute.write(classRoute.route.last == '/' ? classRoute.route : '${classRoute.route}/');
    }

    bufferRoute.write(route.route.first == '/' ? route.route.extractFrom(since: 1) : route.route);

    final parts = PartsRouteFactory.build(route: bufferRoute.toString()).parts;

    return FunctionalRoute(
      type: route.type,
      routeGuide: parts,
      invoker: FunctionalRouterInvokerReflected(method: method, parent: parent),
      middleware: [
        ...serverMiddleware,
        ...parent.annotations.whereType<IHttpMiddleware>(),
        ...method.annotations.whereType<IHttpMiddleware>(),
      ],
    );
  }

  bool isCompatible({required List<String> parts}) {
    if (parts.isEmpty) {
      return routeGuide.isEmpty;
    }

    if (parts.length != routeGuide.length) {
      return false;
    }

    for (int i = 0; i < routeGuide.length; i++) {
      if (!routeGuide[i].acceptPart(part: parts[i])) {
        return false;
      }
    }

    return true;
  }

  Map<String, dynamic> addValues({required IRequest request}) {
    if (request.url.path == '') {
      return <String, dynamic>{};
    }

    final parts = request.url.path.split('/');

    final values = <String, dynamic>{};

    for (int i = 0; i < routeGuide.length; i++) {
      routeGuide[i].addValue(part: parts[i], namedValues: values);
    }

    return values;
  }
}
