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
                  backgroundColor: Color(int.parse(event['color'].replaceFirst('#', '0xff'))),
                ),
                title: Text(event['title']),
                subtitle: Text("$startDate • $startTime – $endTime"),
                trailing: const Icon(Icons.edit),
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
    );
  }
}
