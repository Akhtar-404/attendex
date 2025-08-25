import '../../../core/dio_client.dart';
import '../../../core/http_error.dart';

class EmployeeApi {
  EmployeeApi() {
    attachInterceptors();
  }

  Future<List<dynamic>> listZones() async {
    final r = await dio.get('/zones');
    return (r.data as List).cast<dynamic>();
  }

  Future<List<dynamic>> listShifts() async {
    final r = await dio.get('/shifts');
    return (r.data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> checkIn({
    required String zoneId,
    required String shiftId,
    required double lat,
    required double lng,
  }) async {
    assert(
      zoneId != 'null' && shiftId != 'null',
      'zoneId/shiftId must not be "null"',
    );
    final r = await dio.post(
      '/attendance/check-in',
      data: {'zoneId': zoneId, 'shiftId': shiftId, 'lat': lat, 'lng': lng},
    );
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> checkOut({
    required double lat,
    required double lng,
  }) async {
    final r = await dio.post(
      '/attendance/check-out',
      data: {'lat': lat, 'lng': lng},
    );
    return Map<String, dynamic>.from(r.data);
  }
}
