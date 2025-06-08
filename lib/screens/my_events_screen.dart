import 'package:calendar_application/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event_form_screen.dart';

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("You must be logged in."));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('createdBy', isEqualTo: uid)
            .orderBy('startTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No events found."));
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index].data() as Map<String, dynamic>;
              final startDate = event['startTime'].substring(0, 10);
              final startTime = event['startTime'].substring(11, 16);
              final endTime = event['endTime'].substring(11, 16);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    int.parse(event['color'].replaceFirst('#', '0xff')),
                  ),
                ),
                title: Text(event['title']),
                subtitle: Text("$startDate • $startTime – $endTime"),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventFormScreen(
                            selectedDate: DateTime.parse(event['startTime']),
                            eventData: event,
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete Event"),
                          content: const Text("Are you sure you want to delete this event?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(event['id'])
                            .delete();
                        
                        await NotificationService.cancelNotification(event['id'].hashCode);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Event deleted")),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text("Edit")),
                    PopupMenuItem(value: 'delete', child: Text("Delete")),
                  ],
                ),
              );

            },
          );
        },
      ),
    );
  }
}
