import 'dart:async';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:maxi_library_online/src/error_handling/negative_result_http.dart';
import 'package:maxi_library_online/src/http_server/server/functional_route.dart';
import 'package:maxi_library_online/src/http_server/server/search_server_method.dart';
import 'package:meta/meta.dart';

abstract class HttpServerImplementation<T> {
  final List<FunctionalRoute> routes;
  final dynamic Function(IRequest) routeNotFound;

  late final SearchServerMethod _searcher;
  late bool _isActive;
  Completer? _waitFinish;

  T generateReturnPackage(dynamic value);

  bool get isActive => _isActive;

  Future<void> waitFinish() {
    _waitFinish ??= Completer();
    return _waitFinish!.future;
  }

  @protected
  Future<void> startServerImplementation();

  @protected
  Future<void> closeServerImplementation({bool forced = false});

  Future<void> startServer() async {
    if (_isActive) {
      return;
    }

    await startServerImplementation();

    _isActive = true;
  }

  Future<void> closeServer({bool forced = false}) async {
    if (!_isActive) {
      return;
    }

    await closeServerImplementation(forced: forced);
    _waitFinish?.complete();
    _waitFinish = null;

    _isActive = false;
  }

  static dynamic _routeNotFoundStandar(IRequest request) {
    return NegativeResultHttp(
      identifier: NegativeResultCodes.nonExistent,
      message: tr('The defined route does not lead anywhere'),
      httpErrorCode: 404,
    );
  }

  HttpServerImplementation({
    required this.routes,
    dynamic Function(IRequest)? routeNotFound,
    bool startActive = false,
  })  : routeNotFound = routeNotFound ?? _routeNotFoundStandar,
        _isActive = startActive {
    _searcher = SearchServerMethod(routes: routes);
  }

  bool shouldRetriggerException(ex);

  Future<T> processRequest({required IRequest request}) async {
    dynamic returnValue;

    try {
      returnValue = await _makeInvocation(request);
    } catch (ex) {
      if (shouldRetriggerException(ex)) {
        rethrow;
      }
      returnValue = NegativeResult.searchNegativity(item: ex, actionDescription: tr('Execute function'));
    }

    if (returnValue is IReactiveFunctionality) {
      returnValue = await _generateSocketReactiveByRequest(value: returnValue, request: request);
    } else if (returnValue is BidirectionalStreamFactory) {
      returnValue = await _generateSocketFactorylByRequest(value: returnValue, request: request);
    } else if (returnValue is IBidirectionalStream) {
      returnValue = await _generateSocketBidirectionalByRequest(value: returnValue, request: request);
    } else if (returnValue is Stream) {
      returnValue = await _generateSocketStreamByRequest(value: returnValue, request: request);
    } else if (returnValue is StreamSink) {
      returnValue = await _generateSocketSinkByRequest(value: returnValue, request: request);
    }

    return generateReturnPackage(returnValue);
  }

  Future _makeInvocation(IRequest request) async {
    final (method, namedPart) = _searcher.search(request: request);
    if (method == null) {
      return await routeNotFound(request);
    }

    final values = Map.of(request.valuesInRoute);
    values.addAll(namedPart);

    for (final midd in method.middleware) {
      await midd.invokeMiddleware(namedValues: values, request: request);
    }

    return await method.invoker.invokeMethod(namedValues: values, request: request);
  }

  Future<dynamic> createWebSocket({
    required IRequest request,
    required Function(IBidirectionalStream) onConnection,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  });

  Future _generateSocketStreamByRequest({required Stream value, required IRequest request}) {
    return createWebSocket(
        request: request,
        onConnection: (x) {
          x.joinWithStream(stream: value, selfCloseIfStreamClosed: true);
        });
  }

  Future _generateSocketSinkByRequest({required StreamSink value, required IRequest request}) {
    return createWebSocket(
        request: request,
        onConnection: (x) {
          x.joinWithSick(sink: value, closeExternalStreamIfClose: true);
        });
  }

  Future _generateSocketBidirectionalByRequest({required IBidirectionalStream value, required IRequest request}) {
    return createWebSocket(
        request: request,
        onConnection: (x) {
          x.joinWithOther(other: value, closeExternalStreamIfClose: true, selfCloseIfStreamClosed: true);
        });
  }

  Future _generateSocketFactorylByRequest({required BidirectionalStreamFactory value, required IRequest request}) {
    return createWebSocket(
        request: request,
        onConnection: (x) {
          value.initializeStream(receiver: x.receiver, sender: x, closeExternalStreamIfClose: true);
        });
  }

  Future _generateSocketReactiveByRequest({required IReactiveFunctionality value, required IRequest request}) {
    return createWebSocket(
        request: request,
        onConnection: (x) {
          value.connect(input: x.receiver, output: x);
        });
  }
}
