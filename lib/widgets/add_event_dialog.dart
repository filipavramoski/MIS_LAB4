import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/exam_event.dart';

class AddEventDialog extends StatefulWidget {
  final Function(ExamEvent) onEventAdded;
  final LatLng? initialLocation;

  AddEventDialog({
    required this.onEventAdded,
    this.initialLocation,
  });

  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? LatLng(42.004186, 21.409904);
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
              decoration: InputDecoration(labelText: 'Location Description'),
            ),
            ListTile(
              title: Text('Date & Time'),
              subtitle: Text(_selectedDateTime.toString()),
              onTap: _selectDateTime,
            ),
            Container(
              height: 200,
              margin: EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (LatLng position) {
                    setState(() => _selectedLocation = position);
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(position),
                    );
                  },
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: MarkerId('selected_location'),
                            position: _selectedLocation!,
                          ),
                        }
                      : {},
                ),
              ),
            ),
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
          onPressed: _submitEvent,
        ),
      ],
    );
  }

  void _selectDateTime() async {
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
  }

  void _submitEvent() {
    if (_selectedLocation == null) return;

    final event = ExamEvent(
      title: _titleController.text,
      dateTime: _selectedDateTime,
      location: _locationController.text,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    widget.onEventAdded(event);
    Navigator.of(context).pop();
  }
}
