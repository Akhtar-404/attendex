import 'package:attendex_app/core/dio_client.dart';
import 'package:attendex_app/core/http_error.dart';

class AdminApi {
  AdminApi() {
    attachInterceptors();
  }

  // ------- ZONES -------
  Future<List<dynamic>> listZones() async {
    try {
      final r = await dio.get('/zones');
      return (r.data as List).cast<dynamic>();
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> createZone({
    required String name,
    required double lat,
    required double lng,
    required double radiusMeters,
  }) async {
    try {
      final r = await dio.post(
        '/zones',
        data: {
          'name': name,
          'lat': lat,
          'lng': lng,
          'radiusMeters': radiusMeters,
        },
      );
      return Map<String, dynamic>.from(r.data as Map);
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> updateZone({
    required String id,
    String? name,
    double? lat,
    double? lng,
    double? radiusMeters,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (lat != null && lng != null) {
        body['lat'] = lat;
        body['lng'] = lng;
      }
      if (radiusMeters != null) body['radiusMeters'] = radiusMeters;
      final r = await dio.patch('/zones/$id', data: body);
      return Map<String, dynamic>.from(r.data as Map);
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  Future<void> deleteZone(String id) async {
    try {
      await dio.delete('/zones/$id');
    } catch (e) {
      throw Exception(prettyDioError(e));
    } // typo-safe? fix:
    // ignore: dead_code
  }

  // ------- SHIFTS -------
  Future<List<dynamic>> listShifts() async {
    try {
      final r = await dio.get('/shifts');
      return (r.data as List).cast<dynamic>();
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> createShift({
    required String name,
    required String start, // "HH:mm"
    required String end, // "HH:mm"
  }) async {
    try {
      final r = await dio.post(
        '/shifts',
        data: {'name': name, 'start': start, 'end': end},
      );
      return Map<String, dynamic>.from(r.data as Map);
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> updateShift({
    required String id,
    String? name,
    String? start,
    String? end,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (start != null) body['start'] = start;
      if (end != null) body['end'] = end;
      final r = await dio.patch('/shifts/$id', data: body);
      return Map<String, dynamic>.from(r.data as Map);
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  Future<void> deleteShift(String id) async {
    try {
      await dio.delete('/shifts/$id');
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  // ------- USERS (unchanged) -------
  Future<List<dynamic>> listUsers() async {
    try {
      final r = await dio.get('/me');
      return (r.data as List).cast<dynamic>();
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> setUserRole(String id, String role) async {
    try {
      final r = await dio.patch('me/$id/role', data: {'role': role});
      return Map<String, dynamic>.from(r.data as Map);
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }

  Future<Map<String, dynamic>> setUserActive(String id, bool active) async {
    try {
      final r = await dio.patch('/me/$id/active', data: {'active': active});
      return Map<String, dynamic>.from(r.data as Map);
    } catch (e) {
      throw Exception(prettyDioError(e));
    }
  }
}
