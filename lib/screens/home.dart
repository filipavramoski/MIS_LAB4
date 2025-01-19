import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/exam_event.dart';
import '../widgets/add_event_dialog.dart';
import '../services/location_reminder_service.dart';
import 'dart:math' show min, max;

extension DateTimeExtension on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ExamEvent>> _events = {};
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  ExamEvent? _selectedEvent;

  final _reminderService = LocationReminderService();
  @override
  void initState() {
    super.initState();
    // _reminderService.initialize();
    _requestLocationPermission();
    _loadSampleEvents();
    _getCurrentLocation();
    _reminderService
        .startLocationCheck(_events.values.expand((e) => e).toList());
  }

  void _getRouteToEvent(ExamEvent event) async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (_currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              min(_currentPosition!.latitude, event.latitude),
              min(_currentPosition!.longitude, event.longitude),
            ),
            northeast: LatLng(
              max(_currentPosition!.latitude, event.latitude),
              max(_currentPosition!.longitude, event.longitude),
            ),
          ),
          100,
        ),
      );
    }
  }

  @override
  void dispose() {
    _reminderService.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  void _loadSampleEvents() {
    final event1 = ExamEvent(
      title: 'Mathematics Exam',
      dateTime: DateTime.now(),
      location: 'Room 101',
      latitude: 42.004186,
      longitude: 21.409904,
    );

    _events[DateTime.now()] = [event1];
    _addMarkerForEvent(event1);
  }

  // void _addMarkerForEvent(ExamEvent event) {
  //   _markers.add(
  //     Marker(
  //       markerId: MarkerId(event.title),
  //       position: LatLng(event.latitude, event.longitude),
  //       infoWindow: InfoWindow(
  //         title: event.title,
  //         snippet: event.location,
  //       ),
  //     ),
  //   );
  // }

  Future<String> _calculateDistance(ExamEvent event) async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) {
        return 'Distance unavailable';
      }
    }

    double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        event.latitude,
        event.longitude);

    double distanceInKm = distanceInMeters / 1000;
    return '${distanceInKm.toStringAsFixed(2)} km away';
  }

  void _openGoogleMapsNavigation(ExamEvent event) async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    String url;
    if (_currentPosition != null) {
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&destination=${event.latitude},${event.longitude}'
          '&travelmode=driving';
    } else {
      url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=${event.latitude},${event.longitude}';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open Google Maps')));
    }
  }

  void _deleteEvent(ExamEvent event) {
    setState(() {
      _events.forEach((date, events) {
        events.remove(event);
        if (events.isEmpty) {
          _events.remove(date);
        }
      });

      _markers.removeWhere(
        (marker) =>
            marker.markerId.value ==
            '${event.title}_${event.dateTime.millisecondsSinceEpoch}',
      );

      if (_selectedEvent == event) {
        _selectedEvent = null;
      }
    });
  }

  Widget _buildEventCard(ExamEvent event) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              event.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Location: ${event.location}'),
                Text('Date: ${event.dateTime.toString().split('.')[0]}'),
                FutureBuilder<String>(
                  future: _calculateDistance(event),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Distance: ${snapshot.data}',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.route, color: Colors.blue),
                  onPressed: () {
                    setState(() => _selectedEvent = event);
                    _getRouteToEvent(event);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.directions, color: Colors.green),
                  onPressed: () => _openGoogleMapsNavigation(event),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Event'),
                        content:
                            Text('Are you sure you want to delete this event?'),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text('Delete'),
                            onPressed: () {
                              _deleteEvent(event);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exam Schedule'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () async {
              await _getCurrentLocation();
              if (_currentPosition != null) {
                _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude)));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<ExamEvent>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) {
              DateTime dateOnly = DateTime(day.year, day.month, day.day);
              return _events[dateOnly] ?? [];
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerSize: 8,
              markersMaxCount: 4,
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(42.004186, 21.409904),
                zoom: 12,
              ),
              markers: _markers,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
          if (_selectedDay != null && _events[_selectedDay] != null)
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView(
                shrinkWrap: true,
                children: _events[_selectedDay]!
                    .map((event) => _buildEventCard(event))
                    .toList(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddEventDialog(context),
        tooltip: 'Add Exam Event',
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        onEventAdded: (event) {
          setState(() {
            DateTime dateOnly = DateTime(
              event.dateTime.year,
              event.dateTime.month,
              event.dateTime.day,
            );
            if (_events[event.dateTime] == null) {
              _events[event.dateTime] = [];
            }
            _events[event.dateTime]!.add(event);
            _addMarkerForEvent(event);

            _mapController.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(event.latitude, event.longitude),
                15,
              ),
            );
          });
          _reminderService.startLocationCheck(
            _events.values.expand((e) => e).toList(),
          );
        },
        initialLocation: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
      ),
    );
  }

  void _addMarkerForEvent(ExamEvent event) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(
              '${event.title}_${event.dateTime.millisecondsSinceEpoch}'),
          position: LatLng(event.latitude, event.longitude),
          infoWindow: InfoWindow(
            title: event.title,
            snippet:
                '${event.location}\n${event.dateTime.toString().split('.')[0]}',
          ),
          onTap: () {
            setState(() {
              _selectedDay = event.dateTime.dateOnly;
              _focusedDay = event.dateTime;
            });
          },
        ),
      );
    });
  }
}
