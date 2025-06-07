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

String _selectedColorHex = '#2196F3';
class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();


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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must be logged in.")));
        return;
        }

        final uuid = const Uuid().v4(); // Generate unique event ID
        final now = DateTime.now().toIso8601String();
        final startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime!.hour,
        _startTime!.minute,
        ).toIso8601String();

        final endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime!.hour,
        _endTime!.minute,
        ).toIso8601String();

        await FirebaseFirestore.instance.collection('events').doc(uuid).set({
            "id": uuid,
            "title": _titleController.text,
            "description": _descriptionController.text,
            "startTime": startDateTime,
            "endTime": endDateTime,
            "createdBy": user.uid,
            "color": _selectedColorHex,
            "createdAt": now,
        });

        //10 min before
        final notifyTime = DateTime.parse(startDateTime).subtract(const Duration(minutes: 10));

        //Use ID hashCode as notification ID
        await NotificationService.scheduleNotification(
          id: uuid.hashCode,
          title: "Upcoming Event",
          body: _titleController.text,
          scheduledTime: notifyTime,
        );


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event created: ${_titleController.text}")),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventData != null) {
      _selectedColorHex = widget.eventData!['color'] ?? '#2196F3';
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Add Event")),
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
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    radius: isSelected ? 22 : 18,
                ),
                );
            }).toList(),
            ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Create Event"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
