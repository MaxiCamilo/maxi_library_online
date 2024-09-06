import 'package:maxi_library_online/src/reflected_server/irequest.dart';

mixin IJwtAlgorithm<T> {
  Future<T> checkRequestToker({required IRequest request});
  Future<String> generateToken({required IRequest request});
}
