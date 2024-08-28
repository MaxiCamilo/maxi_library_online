import 'package:shelf/shelf.dart';

mixin IJwtAlgorithm<T> {
  Future<T> checkRequestToker({required Request request});
  Future<String> generateToken({required Request request});
}
