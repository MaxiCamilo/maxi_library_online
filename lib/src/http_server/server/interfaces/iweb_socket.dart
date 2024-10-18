import 'dart:async';

mixin IWebSocket implements StreamSink {
  Stream get stream;

  bool get isActive;
}
