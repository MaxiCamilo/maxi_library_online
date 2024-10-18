import 'package:maxi_library/maxi_library.dart';
import 'package:maxi_library_online/maxi_library_online.dart';
import 'package:maxi_library_online/src/http_server/partsRoutes/fixed_part_route.dart';
import 'package:maxi_library_online/src/http_server/partsRoutes/named_part_route.dart';
import 'package:maxi_library_online/src/http_server/server/functional_route.dart';

class SearchServerMethod {
  final List<FunctionalRoute> routes;

  late final List<FunctionalRoute> getsRoutes;
  late final List<FunctionalRoute> postRoutes;
  late final List<FunctionalRoute> putRoutes;
  late final List<FunctionalRoute> deleteRoutes;

  SearchServerMethod({required this.routes}) {
    getsRoutes = routes.where((x) => x.type == HttpMethodType.getMethod).toList(growable: false);
    postRoutes = routes.where((x) => x.type == HttpMethodType.postMethod).toList(growable: false);
    putRoutes = routes.where((x) => x.type == HttpMethodType.putMethod).toList(growable: false);
    deleteRoutes = routes.where((x) => x.type == HttpMethodType.deleteMethod).toList(growable: false);
    
  }

  (FunctionalRoute?, Map<String, dynamic>) search({required IRequest request}) {
    final selectedList = switch (request.methodType) {
      HttpMethodType.postMethod => postRoutes,
      HttpMethodType.getMethod => getsRoutes,
      HttpMethodType.deleteMethod => deleteRoutes,
      HttpMethodType.putMethod => putRoutes,
      HttpMethodType.anyMethod => routes,
    };

    final parts = request.url.path.split('/');
    final namedParameters = <String, dynamic>{};

    if (parts.isNotEmpty && parts.last.isEmpty) {
      parts.removeLast();
    }

    if (parts.isEmpty) {
      parts.add('');
    }

    final candidates = selectedList.where((x) => x.isCompatible(parts: parts)).toList();

    late final FunctionalRoute selected;

    if (candidates.isEmpty) {
      return (null, namedParameters);
    } else if (candidates.length == 1) {
      selected = candidates.first;
    } else {
      final posible = _getBestCandidate(candidates: candidates, request: request);
      if (posible == null) {
        return (null, namedParameters);
      }

      selected = posible;
    }

    for (int i = 0; i < parts.length; i++) {
      if (selected.routeGuide[i] is NamedPartRoute) {
        (selected.routeGuide[i] as NamedPartRoute).addValue(part: parts[i], namedValues: namedParameters);
      }
    }
    return (selected, namedParameters);
  }

  FunctionalRoute? _getBestCandidate({required IRequest request, required List<FunctionalRoute> candidates}) {
    final fixedCandidate = candidates.selectItem((x) => x.routeGuide.last is FixedPartRoute);

    if (fixedCandidate != null) {
      return fixedCandidate;
    }

    final namedCandidates = candidates.where((x) => x.routeGuide.last is NamedParameter).toList();
    if (namedCandidates.isEmpty) {
      throw NegativeResult(
        identifier: NegativeResultCodes.implementationFailure,
        message: tr('Path %1 is not valid route', [request.url.path]),
      );
    } else if (namedCandidates.length > 1) {
      throw NegativeResult(
        identifier: NegativeResultCodes.implementationFailure,
        message: tr('Path %1 has multiple routes (%2 routes)', [request.url.path, namedCandidates.length]),
      );
    } else {
      return namedCandidates.first;
    }
  }
}
