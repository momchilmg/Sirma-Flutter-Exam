import 'package:calendar_application/screens/event_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  String get _currentFormatLabel {
    switch (_calendarFormat) {
      case CalendarFormat.month:
        return 'Month';
      case CalendarFormat.week:
        return 'Week';
      default:
        return 'Day';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        actions: [
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.view_agenda),
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: CalendarFormat.month, child: Text("Month View")),
              PopupMenuItem(value: CalendarFormat.week, child: Text("Week View")),
              PopupMenuItem(value: CalendarFormat.twoWeeks, child: Text("Two Week View")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
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
            headerStyle: const HeaderStyle(formatButtonVisible: false),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.today),
                  const SizedBox(width: 8),
                  Text(
                    'Selected: ${_selectedDay!.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(child: Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('events').orderBy('startTime').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No events."));
                  }

                  final selectedDateStr = _selectedDay?.toIso8601String().split('T').first;

                  final events = snapshot.data!.docs.where((doc) {
                    final start = doc['startTime'] as String;
                    return start.startsWith(selectedDateStr ?? '');
                  }).toList();

                  if (events.isEmpty) {
                    return const Center(child: Text("No events for this day."));
                  }

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse(event['color'].replaceFirst('#', '0xff'))),
                        ),
                        title: Text(event['title']),
                        subtitle: Text("${event['startTime'].substring(11, 16)} - ${event['endTime'].substring(11, 16)}"),
                        trailing: const Icon(Icons.event),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventFormScreen(
                                selectedDate: DateTime.parse(event['startTime']),
                                eventData: event,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () {
        if (_selectedDay == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a date first.")),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventFormScreen(
              selectedDate: _selectedDay!,
            ),
          ),
        );
      },
      child: const Icon(Icons.add),
    ),
        );
  }
}
