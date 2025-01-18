import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/exam_event.dart';
import '../widgets/add_event_dialog.dart';
import '../services/location_reminder_service.dart';

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
      // Location services are not enabled
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission denied forever
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

  void _addMarkerForEvent(ExamEvent event) {
    _markers.add(
      Marker(
        markerId: MarkerId(event.title),
        position: LatLng(event.latitude, event.longitude),
        infoWindow: InfoWindow(
          title: event.title,
          snippet: event.location,
        ),
      ),
    );
  }

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
                              color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.directions, color: Colors.blue),
              onPressed: () => _openGoogleMapsNavigation(event),
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
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
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
              return _events[day] ?? [];
            },
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(42.004186, 21.409904),
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
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
            if (_events[event.dateTime] == null) {
              _events[event.dateTime] = [];
            }
            _events[event.dateTime]!.add(event);
            _addMarkerForEvent(event);
          });
        },
      ),
    );
  }
}
