import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_server/interfaces/ifunctional_route_invoker.dart';
import 'package:maxi_library_online/src/http_server/irequest.dart';

class FunctionalRouterInvokerReflected with IFunctionalRouteInvoker {
  final IMethodReflection method;
  final ITypeClassReflection parent;

  const FunctionalRouterInvokerReflected({required this.method, required this.parent});

  @override
  Future invokeMethod({required Map<String, dynamic> namedValues, required IRequest request}) async {
    namedValues['request'] = request;

    late final dynamic value;

    if (method.isStatic) {
      value = method.callMethod(instance: null, fixedParametersValues: [request], namedParametesValues: namedValues);
    } else {
      final newEntity = parent.buildEntity(fixedParametersValues: [request], namedParametersValues: namedValues);
      value = method.callMethod(instance: newEntity, fixedParametersValues: [request], namedParametesValues: namedValues);
    }

    if (value is Future) {
      return await value;
    } else {
      return value;
    }
  }
}
