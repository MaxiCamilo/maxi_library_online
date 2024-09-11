import 'package:maxi_library_online/maxi_library_online.dart';

mixin IHttpMiddleware {
  Future<void> invokeMiddleware({required Map<String, dynamic> namedValues, required IRequest request});
}
