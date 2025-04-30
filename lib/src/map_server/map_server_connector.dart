import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:maxi_library_online/src/map_server/map_server_prefix.dart';

class MapServerConnector with IHttpRequester, StartableFunctionality, FunctionalityWithLifeCycle {
  final Stream<Map<String, dynamic>> receiver;
  final StreamSink<Map<String, dynamic>> sender;

  bool _wasInitialize = false;
  Completer<int>? _newTaskWaiter;

  final Map<int, Completer<ResponseHttpRequest<String>>> _activeTask = {};
  final Map<int, IMasterChannel> _activeChannels = {};

  @override
  bool get isActive => isInitialized;

  final _taskSemaphone = Semaphore();

  MapServerConnector({
    required this.receiver,
    required this.sender,
  });

  

  @override
  Future<void> afterInitializingFunctionality() async {
    if (_wasInitialize) {
      throw NegativeResult(
        identifier: NegativeResultCodes.contextInvalidFunctionality,
        message: const Oration(message: 'The server was already active, you must create a new one'),
      );
    }

    joinEvent(event: receiver, onData: onDataReceiver, onDone: close);

    joinFuture(sender.done, whenCompleted: close);

    _wasInitialize = true;
  }

  @override
  void close() {
    _activeChannels.entries.iterar((x) => x.value.close());
    _activeChannels.clear();

    _activeTask.entries.iterar(
      (x) => x.value.completeErrorIfIncomplete(NegativeResult(
        identifier: NegativeResultCodes.functionalityCancelled,
        message: const Oration(message: 'The server connector is being closed'),
      )),
    );
    _activeTask.clear();

    dispose();
  }

  @override
  Future<ResponseHttpRequest<T>> executeRequest<T>({
    required HttpMethodType type,
    required String url,
    bool badStatusCodeIsNegativeResult = true,
    Duration? timeout,
    Object? content,
    Map<String, String>? headers,
    Encoding? encoding,
    int? maxSize,
  }) async {
    checkProgrammingFailure(
      thatChecks: const Oration(message: 'Request must be a String, List<int> or Map<String,dynamic>'),
      result: () => (T == dynamic || T == String || T == List || T == Uint8List || T == Map<String, dynamic>),
    );
    await initialize();
    final (taskID, waiter) = await _taskSemaphone.execute(
      function: () => _createTask(
        type: type,
        url: url,
        content: formatContent(content),
        encoding: encoding,
        headers: headers,
        maxSize: maxSize,
        timeout: timeout,
      ),
    );

    final response = await waiter.future;

    if (maxSize != null && volatile(detail: Oration(message: 'The response from %1 did not return the body size', textParts: [url]), function: () => response.content.length) > maxSize) {
      throw NegativeResult(
        identifier: NegativeResultCodes.resultInvalid,
        message: Oration(message: 'The request for %1 would return information of size %2 bytes, but the maximum supported is %3', textParts: [url, response.content.length, maxSize]),
      );
    }

    if (badStatusCodeIsNegativeResult && response.codeResult >= 400) {
      final error = tryToInterpretError(codeError: response.codeResult, content: response.content, url: url);
      if (T == NegativeResult) {
        return ResponseHttpRequest<T>(content: error as T, codeResult: response.codeResult, url: url);
      } else {
        throw error;
      }
    }

    if (T == String || T == dynamic) {
      return response as ResponseHttpRequest<T>;
    } else if (T == Uint8List || T == List<int>) {
      return ResponseHttpRequest<T>(content: base64.decode(response.content) as T, codeResult: response.codeResult, url: url);
    } else if (T == Map<String, dynamic>) {
      return ResponseHttpRequest<T>(content: ConverterUtilities.interpretToObjectJson(text: response.content, extra: Oration(message: 'from the server')) as T, codeResult: response.codeResult, url: url);
    } else if (T.toString() == 'void') {
      return ResponseHttpRequest<T>(content: '' as T, codeResult: response.codeResult, url: url);
    } else {
      throw NegativeResult(
        identifier: NegativeResultCodes.wrongType,
        message: Oration(message: 'This type of request only returns string or Uint8List'),
      );
    }
  }

  dynamic formatContent(dynamic item) {
    if (item == null) {
      return '';
    }

    if (item is List<int> || item is String) {
      return item;
    }

    if (item is List) {
      return ReflectionManager.serializeListToJson(value: item);
    } else {
      return ReflectionManager.serialzeEntityToJson(value: item);
    }
  }

  Future<(int, Completer<ResponseHttpRequest<String>>)> _createTask({
    required HttpMethodType type,
    required String url,
    Duration? timeout,
    Object? content,
    Map<String, String>? headers,
    Encoding? encoding,
    int? maxSize,
  }) async {
    programmingFailure(reasonFailure: const Oration(message: 'Content must be a String or Binary'), function: () => content == null || content is String || content is List<int>);
    final messageMap = <String, dynamic>{};

    messageMap['\$type'] = MapServerPrefix.clientNewTask;
    messageMap[MapServerPrefix.messageContent] = <String, dynamic>{
      '\$type': MapServerRequest.requestFlag,
      'url': url,
      'headers': headers ?? {},
      'methodType': type.index,
      'contentType': content is List<int> ? 'binary' : 'text',
      'content': content is List<int> ? base64.encode(content) : content ?? '',
    };

    _newTaskWaiter = joinWaiter<int>();
    sender.add(messageMap);

    final taskID = await _newTaskWaiter!.future;

    final completer = MaxiCompleter<ResponseHttpRequest<String>>();
    _activeTask[taskID] = completer;

    return (taskID, completer);
  }

  @override
  Future<IChannel> executeWebSocket({
    required String url,
    bool disableIfNoOneListens = true,
    Map<String, String>? headers,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    await initialize();

    final result = await executeRequestReceivingJsonObject(type: HttpMethodType.webSocket, url: url);
    final channelID = result.getRequiredValueWithSpecificType<int>(MapServerPrefix.taskID);
    final channel = MasterChannel(closeIfEveryoneClosed: disableIfNoOneListens);

    _activeChannels[channelID] = channel;

    final slaver = channel.createSlave();

    channel.done.whenComplete(() => _activeChannels.remove(channelID));

    channel.receiver.listen(
      (x) => sender.add({
        '\$type': MapServerPrefix.clientChannelItem,
        MapServerPrefix.taskID: channelID,
        MapServerPrefix.serverIsCorrect: true,
        MapServerPrefix.messageContent: IHttpServer.formatContent(x),
        MapServerPrefix.serverHttpResponseID: x is NegativeResultHttp ? x.httpErrorCode : 500,
      }),
      onError: (x, y) => sender.add({
        '\$type': MapServerPrefix.clientChannelItem,
        MapServerPrefix.taskID: channelID,
        MapServerPrefix.serverIsCorrect: false,
        MapServerPrefix.messageContent: IHttpServer.formatContent(x),
        MapServerPrefix.serverHttpResponseID: x is NegativeResultHttp ? x.httpErrorCode : 500,
      }),
      onDone: () => sender.add({
        '\$type': MapServerPrefix.clientCloseChannel,
        MapServerPrefix.taskID: channelID,
      }),
    );

    return slaver;
  }

  void onDataReceiver(Map<String, dynamic> event) {
    final eventType = event.getRequiredValueWithSpecificType<String>('\$type');

    switch (eventType) {
      case MapServerPrefix.serverNewTask:
        final taskID = event.getRequiredValueWithSpecificType<int>(MapServerPrefix.taskID);
        _newTaskWaiter?.completeIfIncomplete(taskID);
        _newTaskWaiter = null;
        break;
      case MapServerPrefix.serverFinishTask:
        _reactFinishTask(event);
        break;

      case MapServerPrefix.serverChannelItem:
        _reactChannelItem(event);
        break;

      case MapServerPrefix.serverCloseChannel:
        _reactChannelClose(event);
        break;
      default:
        log('[MapServerInstance] Option $eventType not valid');
        break;
    }
  }

  void _reactFinishTask(Map<String, dynamic> event) {
    final taskID = event.getRequiredValueWithSpecificType<int>(MapServerPrefix.taskID);
    final isCorrect = event.getRequiredValueWithSpecificType<bool>(MapServerPrefix.serverIsCorrect);

    final taskInstance = _activeTask.remove(taskID);
    if (taskInstance == null) {
      //log('[MapServerConnector] Task $taskID is not exists');
      return;
    }

    final taskStatusCode = event.getRequiredValueWithSpecificType<int>(MapServerPrefix.serverHttpResponseID);
    final taskContentResult = event.getRequiredValueWithSpecificType<String>(MapServerPrefix.messageContent);

    if (isCorrect) {
      taskInstance.complete(ResponseHttpRequest<String>(content: taskContentResult, codeResult: taskStatusCode, url: ''));
    } else {
      final error = NegativeResult.interpretJson(jsonText: taskContentResult);
      taskInstance.completeError(error);
    }
  }

  void _reactChannelItem(Map<String, dynamic> event) {
    final channelID = event.getRequiredValueWithSpecificType<int>(MapServerPrefix.taskID);

    final channel = _activeChannels[channelID];
    if (channel == null) {
      return;
    }

    final isCorrect = event.getRequiredValueWithSpecificType<bool>(MapServerPrefix.serverIsCorrect);
    /**
     sender.add({
        '\$type': MapServerPrefix.serverChannelItem,
        MapServerPrefix.taskID: id,
        MapServerPrefix.serverIsCorrect: true,
        MapServerPrefix.messageContent: IHttpServer.formatContent(x),
      })  
     */
    final content = event.getRequiredValueWithSpecificType<String>(MapServerPrefix.messageContent, '');
    if (isCorrect) {
      channel.add(content);
    } else {
      try {
        channel.addError(NegativeResult.interpretJson(jsonText: content));
      } catch (_) {
        channel.addError(content);
      }
    }
  }

  void _reactChannelClose(Map<String, dynamic> event) {
    final channelID = event.getRequiredValueWithSpecificType<int>(MapServerPrefix.taskID);
    final channel = _activeChannels.remove(channelID);
    if (channel != null) {
      channel.close();
    }
  }
}
