import 'package:calendar_application/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic>? eventData;

  const EventFormScreen({
    super.key,
    required this.selectedDate,
    this.eventData,
  });  

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

final Map<String, Color> colorOptions = {
  '#2196F3': Colors.blue,
  '#4CAF50': Colors.green,
  '#FF9800': Colors.orange,
  '#E91E63': Colors.pink,
  '#9C27B0': Colors.purple,
};

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedColorHex = '#2196F3';
  String _widgetTitle = 'Add Event';
  String _widgetButtonTitle = 'Create Event';


  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  void _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? TimeOfDay.now() : (_startTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.eventData != null) {
      final data = widget.eventData!;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';

      final start = DateTime.parse(data['startTime']);
      final end = DateTime.parse(data['endTime']);

      _startTime = TimeOfDay.fromDateTime(start);
      _endTime = TimeOfDay.fromDateTime(end);

      _selectedColorHex = data['color'] ?? '#2196F3';

      _widgetTitle = 'Edit event';
      _widgetButtonTitle = 'Edit Event';
    }
  }

  void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start and end times.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in.")),
      );
      return;
    }

    final now = DateTime.now();
    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (startDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start time must be in the future.")),
      );
      return;
    }

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time.")),
      );
      return;
    }

    final data = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "startTime": startDateTime.toIso8601String(),
      "endTime": endDateTime.toIso8601String(),
      "color": _selectedColorHex,
    };

    if (widget.eventData != null) {
      //update eevent
      final eventId = widget.eventData!['id'];
      await FirebaseFirestore.instance.collection('events').doc(eventId).update(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event updated.")),
      );
    } else {
      //creating new event
      final uuid = const Uuid().v4();
      final createdAt = now.toIso8601String();

      await FirebaseFirestore.instance.collection('events').doc(uuid).set({
        "id": uuid,
        ...data,
        "createdBy": user.uid,
        "createdAt": createdAt,
      });

      // notification 10 mins before
      final notifyTime = startDateTime.subtract(const Duration(minutes: 10));

      await NotificationService.scheduleNotification(
        id: uuid.hashCode,
        title: "Upcoming Event",
        body: _titleController.text,
        scheduledTime: notifyTime,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event created: ${_titleController.text}")),
      );
    }

    Navigator.pop(context);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_widgetTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description (optional)"),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text("Date: ${widget.selectedDate.day.toString().padLeft(2, '0')}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.year}"),
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_startTime == null
                        ? "Start Time: Not set"
                        : "Start: ${_startTime!.format(context)}"),
                  ),
                  TextButton(
                    onPressed: () => _selectTime(context, true),
                    child: const Text("Pick Start"),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_endTime == null
                        ? "End Time: Not set"
                        : "End: ${_endTime!.format(context)}"),
                  ),
                  TextButton(
                    onPressed: () => _selectTime(context, false),
                    child: const Text("Pick End"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            Text("Pick a Color Label:", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
            spacing: 10,
            children: colorOptions.entries.map((entry) {
                final isSelected = entry.key == _selectedColorHex;
                return GestureDetector(
                onTap: () {
                    setState(() {
                    _selectedColorHex = entry.key;
                    });
                },
                child: CircleAvatar(
                    backgroundColor: entry.value,
                    radius: isSelected ? 22 : 18,
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
                );
            }).toList(),
            ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_widgetButtonTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
