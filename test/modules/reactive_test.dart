import 'dart:developer';

import 'package:maxi_library/maxi_library.dart';

class ReactiveTest extends ReactiveFunctionalityImplementation<String, String> {
  @override
  bool get closeIfSpectatorsEmptry => true;

  int _instanceNum = 1;

  @override
  Stream<String> runFunction() async* {
    int instance = _instanceNum;
    _instanceNum += 1;
    yield 'Hi! time to tell';

    for (int i = 1; i < 6; i++) {
      final text = 'Instance $instance Number $i';
      print(text);
      yield text;
      final receive = await waitReceiveData();
      yield 'Yahoo! You are $receive';
    }

    yield 'Bye bye!';
  }

  @override
  void reactExternalDataReceived(String data) {
    log('Hey! Client send $data');
  }

  @override
  void reactExternalErrorReceived(error) {
    log('Oh No! ${error.toString()}');
  }
}
