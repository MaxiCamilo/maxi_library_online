import 'dart:async';
import 'dart:developer';

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

  @HttpRequestMethod(type: HttpMethodType.webSocket, route: 'interact')
  IChannel<String, String> interact() {
    final controller = MasterChannel<String, String>(closeIfEveryoneClosed: true);

    controller.receiver.listen((x) {
      log('Received: $x');
    });

    controller.done.whenComplete(() => log('Good bye!'));

    scheduleMicrotask(() async {
      await controller.waitForNewConnection(omitIfAlreadyConnection: true);
      for (int i = 1; i < 60; i++) {
        if (controller.isActive) {
          controller.add('Sent $i');
        } else {
          break;
        }

        await Future.delayed(const Duration(seconds: 3));
      }
    });

    Future.delayed(Duration(seconds: 60)).whenComplete(() {
      controller.add('Timeout!');
      controller.close();
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
