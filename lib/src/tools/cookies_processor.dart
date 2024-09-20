import 'package:http/http.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:maxi_library/maxi_library.dart';

class CookiesProcessor {
  final Map<String, String> cookies;

  const CookiesProcessor({required this.cookies});

  factory CookiesProcessor.fromText({required String text}) {
    final slitCookie = text.split(';');
    final result = <String, String>{};

    for (final cookie in slitCookie) {
      final cookiePieces = cookie.split('=');
      if (cookiePieces.length == 2) {
        result[cookiePieces[0]] = cookiePieces[1];
      } else {
        result[cookiePieces[0]] = '';
      }
    }

    return CookiesProcessor(cookies: result);
  }

  factory CookiesProcessor.fromResponse({required Response response}) {
    final setCookies = response.headers['set-cookie'];

    if (setCookies == null) {
      return CookiesProcessor(cookies: <String, String>{});
    }

    return CookiesProcessor.fromText(text: setCookies);
  }

  String generateForHeader() => cookies.entries.map((x) => x.value.isEmpty ? x.key : '${x.key}=${x.value}').join(';');

  void putInRequestServer({required IRequest request}) {
    putInHeader(header: request.headers, propertyName: 'Set-Cookie');
  }

  void putInHeader({required Map<String, String> header, String propertyName = 'Cookie'}) {
    final generatedText = generateForHeader();

    if (!header.containsKey(propertyName) || header[propertyName]!.isEmpty) {
      header[propertyName] = generatedText;
      return;
    }

    final original = header[propertyName]!;
    header[propertyName] = '$original${original.last == ';' ? '' : ';'}$generatedText';
  }

  Map<String, String> createNewHeader({String propertyName = 'Cookie'}) {
    final newMap = <String, String>{};
    putInHeader(header: newMap, propertyName: propertyName);
    return newMap;
  }
}
