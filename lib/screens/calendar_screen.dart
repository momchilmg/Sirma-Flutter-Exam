import 'dart:ffi';

import 'package:calendar_application/screens/event_form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _calendarIntFormat = 1;
  String showEventsForThis = 'day';

  final currentUser = FirebaseAuth.instance.currentUser;

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
          PopupMenuButton<int>(
            icon: const Icon(Icons.view_agenda),
            onSelected: (format) {
              showEventsForThis = 'day';
              CalendarFormat cf = CalendarFormat.month;
              if (format == 2) {
                //week
                cf = CalendarFormat.week;
                showEventsForThis = 'week';
              }
              else if (format == 3) {
                showEventsForThis = 'month';
              }
              setState(() {
                _calendarFormat = cf;
                _calendarIntFormat = format;
                _selectedDay = null;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 1, child: Text("Day View")),
              PopupMenuItem(value: 2, child: Text("Week View")),
              PopupMenuItem(value: 3, child: Text("Month View")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              DateTime? startDate = selectedDay.copyWith(hour: 0, minute: 0, second: 0);
              DateTime? endDate = selectedDay.copyWith(hour: 23, minute: 59, second: 59);
              if (_calendarIntFormat == 3) {
                //month
                startDate = DateTime(startDate.year, startDate.month, 1, startDate.hour, startDate.minute, startDate.second);
                endDate = DateTime(endDate.year, endDate.month + 1, 0, endDate.hour, endDate.minute, endDate.second);
              }
              else if (_calendarIntFormat == 2) {
                //week
                startDate = startDate.subtract(Duration(days: startDate.weekday - 1));
                endDate = endDate.add(Duration(days: DateTime.daysPerWeek - endDate.weekday));
              }
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _startDate = startDate;
                _endDate = endDate;
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
                    'Selected: ${_selectedDay!.toLocal().toString().split(' ')[0]} (events this $showEventsForThis)' ,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(child: Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('startTime', isGreaterThanOrEqualTo: _startDate!.toIso8601String())
                  .where('startTime', isLessThan: _endDate!.toIso8601String())
                  .orderBy('startTime')
                  .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No events."));
                  }

                  final events = snapshot.data?.docs ?? [];

                  if (events.isEmpty) {
                    return const Center(child: Text("No events for this period."));
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
                          if (currentUser != null && currentUser!.uid == event['createdBy']) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventFormScreen(
                                  selectedDate: DateTime.parse(event['startTime']),
                                  eventData: event,
                                ),
                              ),
                            );
                          }
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
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("This feature is only for registered users.")),
            );
            return; 
          }
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
                eventData: null,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
        );
  }
}
