import 'dart:async';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
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

    if (returnValue is IPipe) {
      returnValue = await createWebSocketForPipe(pipe: returnValue, request: request);
    } else if (returnValue is Stream) {
      returnValue = await createWebSocketForStream(stream: returnValue, request: request);
    } else if (returnValue is StreamSink) {
      returnValue = await createWebSocketForSink(request: request, sink: returnValue);
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

  Future<dynamic> createWebSocketForStream({
    required IRequest request,
    required Stream stream,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  });

  Future<dynamic> createWebSocketForSink({
    required IRequest request,
    required StreamSink sink,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  });

  Future<dynamic> createWebSocketForPipe({
    required IRequest request,
    required IPipe pipe,
    Iterable<String>? protocols,
    Iterable<String>? allowedOrigins,
    Duration? pingInterval,
  });
/*
  Future _generateSocketStreamByRequest({required Stream value, required IRequest request}) {
    return createWebSocket(
        request: request,
        onConnection: (x) {
          x.joinWithStream(stream: value, selfCloseIfStreamClosed: true);
        });
  }
  */
}
