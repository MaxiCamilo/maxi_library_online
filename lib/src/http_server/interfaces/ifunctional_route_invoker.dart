import 'package:maxi_library_online/maxi_library_online.dart';

mixin IFunctionalRouteInvoker {
  Future invokeMethod({required Map<String, dynamic> namedValues, required IRequest request});
}
