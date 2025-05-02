import 'dart:async';
import 'dart:developer';

import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/src/http_server/server/search_server_method.dart';
import 'package:maxi_library_online/src/map_server/map_server_prefix.dart';

class MapServerInstance with IHttpServer, StartableFunctionality {
  final Stream<Map<String, dynamic>> receiver;
  final StreamSink<Map<String, dynamic>> sender;
  final List<FunctionalRoute> routes;

  final List<IHttpMiddleware> generalMiddleware;

  int _lastTaskID = 1;
  bool _wasActive = false;

  late final StreamSubscription<Map<String, dynamic>> receiverSubscription;
  late final SearchServerMethod _searcher;

  final Map<int, ISlaveChannel> _slaveChannels = {};

  @override
  bool get isActive => _wasActive;

  Completer? _finishWaiter;

  MapServerInstance({required this.receiver, required this.sender, required this.routes, this.generalMiddleware = const []});

  factory MapServerInstance.fromReflection({
    required Stream<Map<String, dynamic>> receiver,
    required StreamSink<Map<String, dynamic>> sender,
    List<IHttpMiddleware> serverMiddleware = const [],
    /*dynamic Function(IRequest)? routeNotFound,*/
    List<ITypeEntityReflection>? entityList,
  }) {
    final routes = IHttpServer.getAllRouteByReflection(serverMiddleware: serverMiddleware, entityList: entityList);
    return MapServerInstance(
      receiver: receiver,
      sender: sender,
      routes: routes,
      generalMiddleware: serverMiddleware,
    );
  }

  @override
  Future<void> startServer() => initialize();

  @override
  Future<void> waitFinish() async {
    await initialize();
    _finishWaiter ??= MaxiCompleter();
    await _finishWaiter!.future;
  }

  @override
  Future<void> initializeFunctionality() async {
    if (_wasActive) {
      throw NegativeResult(
        identifier: NegativeResultCodes.contextInvalidFunctionality,
        message: const Oration(message: 'The server was already active, you must create a new one'),
      );
    }

    _wasActive = true;
    _searcher = SearchServerMethod(routes: routes);

    receiverSubscription = receiver.listen(
      _onDataReceiver,
      onDone: () => dispose(),
    );

    sender.done.whenComplete(() => dispose());
  }

  @override
  Future<void> closeServer({bool forced = false}) async => dispose();

  @override
  void performObjectDiscard() {
    super.performObjectDiscard();

    sender.close();
    receiverSubscription.cancel();

    _slaveChannels.entries.iterar((x) => x.value.close());
    _slaveChannels.clear();
  }

  void _onDataReceiver(Map<String, dynamic> event) {
    if (!isActive) {
      return;
    }

    final messageType = event['\$type']?.toString() ?? '';
    if (messageType.isEmpty) {
      log('[MapServerInstance] A message was received without a specified type');
      return;
    }

    try {
      switch (messageType) {
        case MapServerPrefix.clientNewTask:
          final id = _lastTaskID;
          _lastTaskID += 1;
          sender.add({
            '\$type': MapServerPrefix.serverNewTask,
            MapServerPrefix.taskID: id,
          });
          maxiScheduleMicrotask(() => _createNewTask(id: id, event: event));
          break;
        case MapServerPrefix.clientChannelItem:
          _reactNewItemChannel(event);
          break;

        case MapServerPrefix.clientCloseChannel:
          _reactClientCloseChannel(event);
          break;
        default:
          log('[MapServerInstance] Option $messageType not valid');
          break;
      }
    } catch (ex) {
      log('[MapServerInstance] $ex');
      dispose();
    }
  }

  Future<void> _createNewTask({required int id, required Map<String, dynamic> event}) async {
    try {
      await _createNewTaskAsegurate(event: event, id: id);
    } catch (ex) {
      final error = NegativeResult.searchNegativity(item: ex, actionDescription: const Oration(message: 'Execute request'));
      _sendError(error: error, id: id);
    }
  }

  void _sendError({required int id, required NegativeResult error}) {
    if (!isInitialized) {
      return;
    }
    sender.add({
      '\$type': MapServerPrefix.serverFinishTask,
      MapServerPrefix.taskID: id,
      MapServerPrefix.serverIsCorrect: false,
      MapServerPrefix.messageContent: error.serializeToJson(),
      MapServerPrefix.serverHttpResponseID: error is NegativeResultHttp ? error.httpErrorCode : 500,
    });
  }

  Future<void> _createNewTaskAsegurate({required int id, required Map<String, dynamic> event}) async {
    final requestContent = volatile(detail: const Oration(message: 'The event must have the request'), function: () => event[MapServerPrefix.messageContent]! as Map<String, dynamic>);
    final request = MapServerRequest.fromMap(server: this, message: requestContent);

    final result = await _makeInvocation(request);

    if (!isActive) {
      return;
    }

    if (result is IMasterChannel) {
      await _makeChannel(id: id, result: result);
    } else if (result is Stream) {
      await _makeStream(id: id, result: result);
    } else {
      _sendTaskResult(id: id, result: result);
    }
  }

  Future<void> _makeStream({required int id, required Stream result}) {
    final master = MasterChannel(closeIfEveryoneClosed: true);

    final subscription = result.listen(
      (x) => master.add(x),
      onError: (x, y) => master.addError(x, y),
      onDone: () => master.close(),
    );

    master.done.whenComplete(() => subscription.cancel());

    return _makeChannel(id: id, result: master);
  }

  Future<void> _makeChannel({required int id, required IMasterChannel result}) async {
    if (result is StartableFunctionality) {
      await (result as StartableFunctionality).initialize();
    }

    final slaver = result.createSlave();

    _slaveChannels[id] = slaver;

    slaver.receiver.listen(
      (x) => sender.add({
        '\$type': MapServerPrefix.serverChannelItem,
        MapServerPrefix.taskID: id,
        MapServerPrefix.serverIsCorrect: true,
        MapServerPrefix.messageContent: IHttpServer.formatContent(x),
      }),
      onError: (x, y) => sender.add({
        '\$type': MapServerPrefix.serverChannelItem,
        MapServerPrefix.taskID: id,
        MapServerPrefix.serverIsCorrect: false,
        MapServerPrefix.messageContent: IHttpServer.formatContent(NegativeResult.searchNegativity(item: x, actionDescription: const Oration(message: 'WebChannel error'))),
      }),
      onDone: () => _closeChannel(id),
    );

    _sendTaskResult(
      id: id,
      result: <String, dynamic>{
        MapServerPrefix.taskID: id,
      },
    );
  }

  void _sendTaskResult({required int id, required dynamic result}) {
    sender.add({
      '\$type': MapServerPrefix.serverFinishTask,
      MapServerPrefix.taskID: id,
      MapServerPrefix.serverIsCorrect: true,
      MapServerPrefix.messageContent: IHttpServer.formatContent(result),
      MapServerPrefix.serverHttpResponseID: result is NegativeResultHttp ? result.httpErrorCode : 200,
    });
  }

  Future _makeInvocation(IRequest request) async {
    final (method, namedPart) = _searcher.search(request: request);
    if (method == null) {
      throw NegativeResultHttp(
        identifier: NegativeResultCodes.nonExistent,
        message: Oration(message: 'The defined route does not lead anywhere'),
        httpErrorCode: 404,
      );
    }

    final values = Map.of(request.valuesInRoute);
    values.addAll(namedPart);

    for (final midd in generalMiddleware) {
      await midd.invokeMiddleware(namedValues: values, request: request);
    }

    for (final midd in method.middleware) {
      await midd.invokeMiddleware(namedValues: values, request: request);
    }

    return await method.invoker.invokeMethod(namedValues: values, request: request);
  }

  Future<void> _reactNewItemChannel(Map<String, dynamic> event) async {
    try {
      final id = event.getRequiredValueWithSpecificType<int>(MapServerPrefix.taskID);
      final channel = _slaveChannels[id];
      if (channel == null) {
        log('[MapServerInstance -> react New item channel] Channel $id does not exists');
        return;
      }

      channel.add(event[MapServerPrefix.messageContent]);
    } catch (ex) {
      log('[MapServerInstance -> react New item channel] $ex');
    }
  }

  Future<void> _reactClientCloseChannel(Map<String, dynamic> event) async {
    try {
      final id = event.getRequiredValueWithSpecificType<int>(MapServerPrefix.taskID);
      final channel = _slaveChannels.remove(id);
      if (channel == null) {
        return;
      }

      channel.close();
    } catch (ex) {
      log('[MapServerInstance -> react New item channel] $ex');
    }
  }

  void _closeChannel(int id) {
    final channel = _slaveChannels.remove(id);
    if (channel != null) {
      channel.close();
      sender.add({
        '\$type': MapServerPrefix.serverCloseChannel,
        MapServerPrefix.taskID: id,
      });
    }
  }

  @override
  Future<void> closeAllWebSockets() async {
    if (isInitialized) {
      _slaveChannels.entries.iterar((x) => x.value.close());
      _slaveChannels.clear();
    }
  }
}
