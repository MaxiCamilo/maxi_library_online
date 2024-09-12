// ignore_for_file: unnecessary_const, unnecessary_import, duplicate_import, unused_import

import 'package:maxi_library/export_reflectors.dart';
import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:test/test.dart';
import 'test.dart';
import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'dart:async';
import 'dart:developer';
import 'package:maxi_library/export_reflectors.dart';
import 'modules/reactive_test.dart';
import 'apis/person_api.dart';
import 'models/person.dart';



/*----------------------------------   Class Person   ----------------------------------*/


/*PERSON FIELDS*/

class _PersonfirstName extends GeneratedReflectedField<Person,String> with GeneratedReflectedModifiableField<Person,String> {
const _PersonfirstName();
@override
List get annotations => const [];

@override
String get name => 'firstName';

@override
bool get isStatic => false;

@override
bool get isConst => false;

@override
bool get isLate => false;

@override
bool get isFinal => false;

@override
bool get acceptNull => false;

@override
bool get hasDefaultValue => true;
@override
String? get defaulValue => 'super name';

@override
String getReservedValue({required Person? entity}) =>
entity!.firstName;
@override
void setReservedValue({required Person? entity, required String newValue}) =>
	entity!.firstName = newValue;
}

class _PersonlastName extends GeneratedReflectedField<Person,String> with GeneratedReflectedModifiableField<Person,String> {
const _PersonlastName();
@override
List get annotations => const [];

@override
String get name => 'lastName';

@override
bool get isStatic => false;

@override
bool get isConst => false;

@override
bool get isLate => false;

@override
bool get isFinal => false;

@override
bool get acceptNull => false;

@override
bool get hasDefaultValue => true;
@override
String? get defaulValue => '';

@override
String getReservedValue({required Person? entity}) =>
entity!.lastName;
@override
void setReservedValue({required Person? entity, required String newValue}) =>
	entity!.lastName = newValue;
}

class _PersonisAdmin extends GeneratedReflectedField<Person,bool> with GeneratedReflectedModifiableField<Person,bool> {
const _PersonisAdmin();
@override
List get annotations => const [];

@override
String get name => 'isAdmin';

@override
bool get isStatic => false;

@override
bool get isConst => false;

@override
bool get isLate => false;

@override
bool get isFinal => false;

@override
bool get acceptNull => false;

@override
bool get hasDefaultValue => true;
@override
bool? get defaulValue => false;

@override
bool getReservedValue({required Person? entity}) =>
entity!.isAdmin;
@override
void setReservedValue({required Person? entity, required bool newValue}) =>
	entity!.isAdmin = newValue;
}

class _Personage extends GeneratedReflectedField<Person,int> with GeneratedReflectedModifiableField<Person,int> {
const _Personage();
@override
List get annotations => const [];

@override
String get name => 'age';

@override
bool get isStatic => false;

@override
bool get isConst => false;

@override
bool get isLate => false;

@override
bool get isFinal => false;

@override
bool get acceptNull => false;

@override
bool get hasDefaultValue => true;
@override
int? get defaulValue => 0;

@override
int getReservedValue({required Person? entity}) =>
entity!.age;
@override
void setReservedValue({required Person? entity, required int newValue}) =>
	entity!.age = newValue;
}

/*PERSON METHODS*/

class _PersonBuilder extends GeneratedReflectedMethod<Person, Person> {
const _PersonBuilder();
@override
String get name => '';

@override
bool get isStatic => true;

@override
MethodDetectedType get methodType => MethodDetectedType.buildMethod;

@override
List get annotations => const [];

@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [];

@override
Person callReservedMethod({required Person? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
Person();
}


/*PERSON INSTANCE*/

class _Person extends GeneratedReflectedClass<Person> {
const _Person();
@override
List get annotations => const [reflect];

@override
Type? get baseClass => null;

@override
List<Type> get classThatImplement => const [];

@override
bool get isAbstract => false;

@override
bool get isMixin => false;

@override
String get name => 'Person';

@override
List<GeneratedReflectedMethod> get methods => const [_PersonBuilder()];

@override
List<GeneratedReflectedField> get fields => const [_PersonfirstName(),_PersonlastName(),_PersonisAdmin(),_Personage()];


}
/*----------------------------------   x   ----------------------------------*/



/*----------------------------------   Class PersonApi   ----------------------------------*/


/*PERSONAPI FIELDS*/

/*PERSONAPI METHODS*/

class _PersonApigetAllPersonMethod extends GeneratedReflectedMethod<PersonApi, List<Person>> {
const _PersonApigetAllPersonMethod();
@override
String get name => 'getAllPerson';

@override
bool get isStatic => false;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.getMethod, route: '')];

@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [];

@override
List<Person> callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
entity!.getAllPerson();
}


class _PersonApigetSpecificPersonMethod extends GeneratedReflectedMethod<PersonApi, Future<Person>> {
const _PersonApigetSpecificPersonMethod();
@override
String get name => 'getSpecificPerson';

@override
bool get isStatic => false;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.getMethod, route: '{id:int}')];

static const _namid = GeneratedReflectedNamedParameter<int>(
      annotations: const [],
      defaultValue: null,
      hasDefaultValue: false,
      acceptNulls: false,
      name: 'id',
)
;@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [_namid];

@override
Future<Person> callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
entity!.getSpecificPerson(id: _namid.getValueFromMap(namedValues),);
}


class _PersonApisayHiMethod extends GeneratedReflectedMethod<PersonApi, String> {
const _PersonApisayHiMethod();
@override
String get name => 'sayHi';

@override
bool get isStatic => false;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.getMethod, route: 'sayHi')];

@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [];

@override
String callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
entity!.sayHi();
}


class _PersonApigetContentMethod extends GeneratedReflectedMethod<PersonApi, Future<void>> {
const _PersonApigetContentMethod();
@override
String get name => 'getContent';

@override
bool get isStatic => true;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.postMethod, route: 'content')];

static const _namrequest = GeneratedReflectedNamedParameter<IRequest>(
      annotations: const [],
      defaultValue: null,
      hasDefaultValue: false,
      acceptNulls: false,
      name: 'request',
)
;@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [_namrequest];

@override
Future<void> callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
PersonApi.getContent(request: _namrequest.getValueFromMap(namedValues),);
}


class _PersonApistreamNumbersMethod extends GeneratedReflectedMethod<PersonApi, Stream<String>> {
const _PersonApistreamNumbersMethod();
@override
String get name => 'streamNumbers';

@override
bool get isStatic => false;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.getMethod, route: 'streamNumbers')];

@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [];

@override
Stream<String> callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
entity!.streamNumbers();
}


class _PersonApiinteractMethod extends GeneratedReflectedMethod<PersonApi, StreamController<String>> {
const _PersonApiinteractMethod();
@override
String get name => 'interact';

@override
bool get isStatic => false;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.getMethod, route: 'interact')];

@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [];

@override
StreamController<String> callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
entity!.interact();
}


class _PersonApibidirectionalMethod extends GeneratedReflectedMethod<PersonApi, BidirectionalStreamFactory> {
const _PersonApibidirectionalMethod();
@override
String get name => 'bidirectional';

@override
bool get isStatic => false;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.getMethod, route: 'bidirectional')];

@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [];

@override
BidirectionalStreamFactory callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
entity!.bidirectional();
}


class _PersonApireactiveMethod extends GeneratedReflectedMethod<PersonApi, ReactiveTest> {
const _PersonApireactiveMethod();
@override
String get name => 'reactive';

@override
bool get isStatic => false;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.getMethod, route: 'reactive')];

@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [];

@override
ReactiveTest callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
entity!.reactive();
}


class _PersonApifinishServerMethod extends GeneratedReflectedMethod<PersonApi, dynamic> {
const _PersonApifinishServerMethod();
@override
String get name => 'finishServer';

@override
bool get isStatic => false;

@override
MethodDetectedType get methodType => MethodDetectedType.commonMethod;

@override
List get annotations => const [HttpRequestMethod(type: HttpMethodType.postMethod, route: 'finishServer')];

static const _namrequest = GeneratedReflectedNamedParameter<IRequest>(
      annotations: const [],
      defaultValue: null,
      hasDefaultValue: false,
      acceptNulls: false,
      name: 'request',
)
;@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [_namrequest];

@override
dynamic callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
entity!.finishServer(request: _namrequest.getValueFromMap(namedValues),);
}


class _PersonApiBuilder extends GeneratedReflectedMethod<PersonApi, PersonApi> {
const _PersonApiBuilder();
@override
String get name => '';

@override
bool get isStatic => true;

@override
MethodDetectedType get methodType => MethodDetectedType.buildMethod;

@override
List get annotations => const [];

@override
List<GeneratedReflectedFixedParameter> get fixedParameters => const [];

@override
List<GeneratedReflectedNamedParameter> get namedParameters => const [];

@override
PersonApi callReservedMethod({required PersonApi? entity, required List fixedValues, required Map<String, dynamic> namedValues}) =>
PersonApi();
}


/*PERSONAPI INSTANCE*/

class _PersonApi extends GeneratedReflectedClass<PersonApi> {
const _PersonApi();
@override
List get annotations => const [reflect,HttpRequestClass(route: 'v1/person')];

@override
Type? get baseClass => null;

@override
List<Type> get classThatImplement => const [];

@override
bool get isAbstract => false;

@override
bool get isMixin => false;

@override
String get name => 'PersonApi';

@override
List<GeneratedReflectedMethod> get methods => const [_PersonApigetAllPersonMethod(),_PersonApigetSpecificPersonMethod(),_PersonApisayHiMethod(),_PersonApigetContentMethod(),_PersonApistreamNumbersMethod(),_PersonApiinteractMethod(),_PersonApibidirectionalMethod(),_PersonApireactiveMethod(),_PersonApifinishServerMethod(),_PersonApiBuilder()];

@override
List<GeneratedReflectedField> get fields => const [];


}
/*----------------------------------   x   ----------------------------------*/



class _AlbumTest extends GeneratedReflectorAlbum {
  const _AlbumTest();
  @override
  List<GeneratedReflectedClass> get classes => const [_Person(),_PersonApi()];

  @override
  List<TypeEnumeratorReflector> get enums => const [];
}


const testReflectors = _AlbumTest();
