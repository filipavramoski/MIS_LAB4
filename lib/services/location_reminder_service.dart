
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_application_1/models/exam_event.dart';
import 'distance_service.dart';

class LocationReminderService {
  Timer? _locationCheckTimer;

  void startLocationCheck(List<ExamEvent> events) {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _checkEventProximity(events);
    });
  }

  Future<void> _checkEventProximity(List<ExamEvent> events) async {
    final position = await Geolocator.getCurrentPosition();

    for (var event in events) {
      double distance = await DistanceService.calculateDistance(event);

      if (distance <= 1.0) {
        
        _onProximity(event);
      }
    }
  }

  void _onProximity(ExamEvent event) {
    
    print('You are near ${event.location} for ${event.title}');
  }

  void dispose() {
    _locationCheckTimer?.cancel();
  }
}
