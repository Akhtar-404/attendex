import 'package:geolocator/geolocator.dart';

class LocationUtil {
  static Future<Position> current() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw 'Location services are disabled';
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      throw 'Location permission denied';
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
