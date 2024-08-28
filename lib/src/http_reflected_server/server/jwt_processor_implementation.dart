import 'dart:async';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_reflected_server/server/interfaces/ijwt_algorithm.dart';
import 'package:shelf/shelf.dart';

abstract class JwtProcessorImplementation<T> with IJwtAlgorithm<T> {
  final String secretKey;
  final JWTAlgorithm algorithm;

  Future<T> checkRequestTokerImplementation({required JWT token, required Request request});
  Future<dynamic> generateTokenImplementation({required Request request});

  const JwtProcessorImplementation({required this.secretKey, this.algorithm = JWTAlgorithm.HS256});

  @override
  Future<T> checkRequestToker({required Request request}) {
    final authHeader = request.headers['Authorization'];

    if (authHeader == null) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidValue,
        message: tr('An authentication token is required'),
      );
    }

    if (!authHeader.startsWith('Bearer ')) {
      throw NegativeResult(
        identifier: NegativeResultCodes.invalidValue,
        message: tr('The authentication token is invalid, it must start with "Bearer "'),
      );
    }

    final tokenText = authHeader.substring(7);
    final token = volatile(detail: () => tr('The authentication token is invalid, is not a valid JWT format'), function: () => JWT.verify(tokenText, SecretKey(secretKey)));

    return checkRequestTokerImplementation(request: request, token: token);
  }

  @override
  Future<String> generateToken({required Request request}) async {
    final jwt = JWT(
      await generateTokenImplementation(request: request),
    );

    return jwt.sign(SecretKey(secretKey), algorithm: algorithm);
  }
}
