import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/exam_event.dart';

class AddEventDialog extends StatefulWidget {
  final Function(ExamEvent) onEventAdded;

  AddEventDialog({required this.onEventAdded});

  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  double _latitude = 42.004186;
  double _longitude = 21.409904;
  void _selectLocation() async {
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(
          height: 300,
          width: 300,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_latitude, _longitude),
              zoom: 15,
            ),
            onTap: (LatLng position) {
              setState(() {
                _latitude = position.latitude;
                _longitude = position.longitude;
              });
              Navigator.pop(context, true);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Exam Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            ListTile(
              title: Text('Date & Time'),
              subtitle: Text(_selectedDateTime.toString()),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2025),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
            // Add fields for latitude and longitude if needed
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Add'),
          onPressed: () {
            final event = ExamEvent(
              title: _titleController.text,
              dateTime: _selectedDateTime,
              location: _locationController.text,
              latitude: _latitude,
              longitude: _longitude,
            );
            widget.onEventAdded(event);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
