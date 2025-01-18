// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:async';
// import 'package:flutter_application_1/models/exam_event.dart';
// import 'distance_service.dart';

// class LocationReminderService {
//   final FlutterLocalNotificationsPlugin notifications =
//       FlutterLocalNotificationsPlugin();
//   Timer? _locationCheckTimer;

//   Future<void> initialize() async {
//     const initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     final initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
//     await notifications.initialize(initializationSettings);
//   }

//   void startLocationCheck(List<ExamEvent> events) {
//     _locationCheckTimer?.cancel();
//     _locationCheckTimer = Timer.periodic(Duration(minutes: 5), (timer) {
//       _checkEventProximity(events);
//     });
//   }

//   Future<void> _checkEventProximity(List<ExamEvent> events) async {
//     final position = await Geolocator.getCurrentPosition();

//     for (var event in events) {
//       double distance = await DistanceService.calculateDistance(event);

//       if (distance <= 1.0) {
//         // Within 1 km
//         _showNotification(event);
//       }
//     }
//   }

//   Future<void> _showNotification(ExamEvent event) async {
//     const androidDetails = AndroidNotificationDetails(
//       'exam_reminders',
//       'Exam Reminders',
//       importance: Importance.high,
//     );

//     await notifications.show(
//       0,
//       'Approaching Exam Location',
//       'You are near ${event.location} for ${event.title}',
//       NotificationDetails(android: androidDetails),
//     );
//   }

//   void dispose() {
//     _locationCheckTimer?.cancel();
//   }
// }
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
        // Within 1 km
        _onProximity(event);
      }
    }
  }

  void _onProximity(ExamEvent event) {
    // Logic to handle proximity (e.g., logging or UI update).
    print('You are near ${event.location} for ${event.title}');
  }

  void dispose() {
    _locationCheckTimer?.cancel();
  }
}
