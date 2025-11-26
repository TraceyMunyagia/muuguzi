// lib/pages/caregiver_reminders_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/caregiver_session.dart';

Future<void> _cleanupExpiredRemindersForPatient(String patientId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('Reminders')
      .where('patientId', isEqualTo: patientId)
      .get();

  final now = DateTime.now();
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final ts = data['date'];
    if (ts is Timestamp) {
      final date = ts.toDate();
      if (date.isBefore(now)) {
        await doc.reference.delete();
      }
    }
  }
}

class CaregiverRemindersPage extends StatelessWidget {
  const CaregiverRemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CaregiverSession.instance;
    final patientId = session.matchedPatientId;

    // No matched patient yet
    if (patientId == null) {
      return const Center(
        child: Text(
          'No patients yet.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Keep reminders tidy by removing expired items for the matched patient.
    Future.microtask(() => _cleanupExpiredRemindersForPatient(patientId));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Reminders') // your actual reminder collection
          .where('patientId', isEqualTo: patientId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to load reminders right now.'),
          );
        }

        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // no reminders
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No reminders yet.',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        // Sort locally so we don't depend on composite Firestore indexes.
        final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs)
          ..sort((a, b) {
            final aDate = (a.data() as Map<String, dynamic>)['date'];
            final bDate = (b.data() as Map<String, dynamic>)['date'];

            final aTs = aDate is Timestamp ? aDate.toDate() : DateTime(0);
            final bTs = bDate is Timestamp ? bDate.toDate() : DateTime(0);
            return aTs.compareTo(bTs);
          });

        final now = DateTime.now();
        final upcomingDocs = <QueryDocumentSnapshot>[];
        final pastDocs = <QueryDocumentSnapshot>[];

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['date'];
          final date = ts is Timestamp ? ts.toDate() : DateTime.now();
          if (date.isBefore(now)) {
            pastDocs.add(doc);
          } else {
            upcomingDocs.add(doc);
          }
        }

        // SAVE to session
        session.reminders =
            upcomingDocs.map((d) => d.data() as Map<String, dynamic>).toList();

        String _formatDate(Map<String, dynamic> data) {
          if (data['date'] is Timestamp) {
            final dt = (data['date'] as Timestamp).toDate();
            return "${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          }
          return '';
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Upcoming appointments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (upcomingDocs.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('No upcoming reminders'),
                ),
              )
            else
              ...upcomingDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Reminder';
                final isCompleted = data['isCompleted'] == true;
                final dateText = _formatDate(data);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (dateText.isNotEmpty) "Date: $dateText",
                        if (isCompleted) "Status: Completed",
                        if (!isCompleted) "Status: Pending"
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
            const SizedBox(height: 16),
            Text(
              'Past appointments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (pastDocs.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('No past reminders'),
                  subtitle: Text('Past reminders are removed automatically.'),
                ),
              )
            else
              ...pastDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Reminder';
                final isCompleted = data['isCompleted'] == true;
                final dateText = _formatDate(data);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (dateText.isNotEmpty) "Date: $dateText",
                        if (isCompleted) "Status: Completed",
                        if (!isCompleted) "Status: Pending",
                        "Scheduled reminder removed after date."
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
