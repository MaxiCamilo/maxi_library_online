import 'dart:async';

import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';

import '../models/person.dart';

@reflect
@HttpRequestClass(route: 'v1/person')
class PersonApi {
  @HttpRequestMethod(type: HttpMethodType.getMethod, route: '')
  List<Person> getAllPerson() {
    return [
      Person()
        ..firstName = 'Maxi'
        ..lastName = 'Camilo'
        ..age = 21
        ..isAdmin = true,
    ];
  }

  @HttpRequestMethod(type: HttpMethodType.getMethod, route: '{id:int}')
  Future<Person> getSpecificPerson({required int id}) async {
    await Future.delayed(Duration(seconds: 3));
    return Person()
      ..firstName = 'Maxi'
      ..lastName = 'Camilo'
      ..age = id
      ..isAdmin = false;
  }

  @HttpRequestMethod(type: HttpMethodType.getMethod, route: 'sayHi')
  String sayHi() {
    return 'Hi!';
  }

  @HttpRequestMethod(type: HttpMethodType.postMethod, route: 'content')
  static Future<void> getContent({required IRequest request}) async {
    final content = await request.readContentAsString();
    print(content);
  }

  @HttpRequestMethod(type: HttpMethodType.getMethod, route: 'streamNumbers')
  Stream<String> streamNumbers() async* {
    print('Over here');
    for (int i = 1; i <= 21; i++) {
      yield 'Hi! now it`s going for number $i';
      await Future.delayed(Duration(seconds: 1));
    }

    yield 'bye bye!';

    print('Finish');
  }

  @HttpRequestMethod(type: HttpMethodType.getMethod, route: 'interact')
  StreamController<String> interact() {
    final controller = StreamController<String>.broadcast();

    controller.stream.listen((x) => print('Sender: $x'));

    Future.delayed(Duration(seconds: 10)).whenComplete(() => controller.close());

    return controller;
  }

  @HttpRequestMethod(type: HttpMethodType.getMethod, route: 'bidirectional')
  BidirectionalStreamFactory bidirectional() {
    final controller = BidirectionalStreamFactory();

    controller.waitInitialize().whenComplete(() {
      controller.receiver.listen((x) => print('Client sent $x'));

      controller.addStream(streamNumbers());

      //Future.delayed(Duration(seconds: 10)).whenComplete(() => controller.close());
    });

    return controller;
  }

  /*
  @HttpRequestMethod(type: HttpMethodType.getMethod, route: 'socket')
  dynamic createWebSocket({required IRequest request}) {
    return request.createWebSocket(onConnection: (stream) async {
      print('Over here');

      stream.receiver.listen((x) => print('Send "$x"'));
      stream.done.whenComplete(() => print('Connection close'));

      for (int i = 1; i <= 21; i++) {
        if (!stream.isActive) {
          break;
        }

        stream.add('Hi! now it`s going for number $i');
        await Future.delayed(Duration(seconds: 5));
      }

      print('Bye!');
      stream.close();
    });
  }
  */
}
