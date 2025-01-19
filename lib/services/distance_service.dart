import 'package:geolocator/geolocator.dart';
import '../models/exam_event.dart';

class DistanceService {
  static Future<double> calculateDistance(ExamEvent event) async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double distanceInMeters = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          event.latitude,
          event.longitude);

      return distanceInMeters / 1000;
    } catch (e) {
      print('Error calculating distance: $e');
      return -1;
    }
  }
}
