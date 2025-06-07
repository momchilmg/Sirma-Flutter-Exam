// lib/screens/event_form_screen.dart
import 'package:flutter/material.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime selectedDate;

  const EventFormScreen({super.key, required this.selectedDate});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select start and end times.")),
        );
        return;
      }

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

      // TODO: Save to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event created: ${_titleController.text}")),
      );

      Navigator.pop(context); // Go back to calendar
    }
  }

  @override
  Widget build(BuildContext context) {
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
