import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:muuguzi_app/services/patient_session.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _titleController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _cleanupTriggered = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initNotifications();
    _triggerCleanupIfPossible();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  void _triggerCleanupIfPossible() {
    final patientId = PatientSession.instance.patientId;
    if (patientId != null && !_cleanupTriggered) {
      _cleanupTriggered = true;
      PatientSession.instance.cleanupExpiredReminders();
    }
  }

  Future<void> _scheduleLocalNotification(DateTime when, String title) async {
    final tz.TZDateTime tzTime = tz.TZDateTime.from(when, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'muuguzi_reminders',
      'Muuguzi Reminders',
      channelDescription: 'Reminder notifications for appointments',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      tzTime.millisecondsSinceEpoch ~/ 1000, // unique-ish id
      'Appointment reminder',
      title,
      tzTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _addReminder() async {
    if (_selectedDay == null || _titleController.text.trim().isEmpty) return;

    // Make sure patient is logged in
    final patientId = PatientSession.instance.patientId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again.')),
      );
      return;
    }

    final now = DateTime.now();
    // Schedule 1 minute from now on the selected day
    final when = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));

    final remindersRef =
        FirebaseFirestore.instance.collection('Reminders'); // match spec

    final title = _titleController.text.trim();

    // Create Firestore reminder
    final docRef = await remindersRef.add({
      // 'remindersid' will be set to docRef.id below
      'title': title,
      'date': Timestamp.fromDate(when),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isCompleted': false,
      // userId removed per your requirement
      'patientId': patientId, // optional if you later want to filter by patient
    });

    // Update remindersid field to match document ID
    await docRef.update({'remindersid': docRef.id});

    // Schedule the local notification
    await _scheduleLocalNotification(when, title);

    // Update session with this new reminder
    final reminderMap = {
      'remindersid': docRef.id,
      'title': title,
      'date': when,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'isCompleted': false,
      'patientId': patientId,
    };

    final session = PatientSession.instance;
    final currentReminders = List<Map<String, dynamic>>.from(session.reminders);
    currentReminders.add(reminderMap);
    session.saveReminders(currentReminders);

    // Clean up any expired reminders after adding a new one.
    await session.cleanupExpiredReminders();

    _titleController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _triggerCleanupIfPossible();
    final patientId = PatientSession.instance.patientId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminders'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null && isSameDay(day, _selectedDay),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Appointment title',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add),
                label: const Text('Add reminder'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: patientId == null
                  ? const Center(
                      child: Text('Please log in to see your reminders.'),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Reminders')
                          // Filter by logged-in patient; sort locally to avoid Firestore index issues.
                          .where('patientId', isEqualTo: patientId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Unable to load reminders',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          PatientSession.instance.saveReminders([]);
                          return const Center(
                            child: Text('No reminders yet. Add one above.'),
                          );
                        }

                        // Sort by date ascending on the client so no composite index is required.
                        final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
                          ..sort((a, b) {
                            final aDate =
                                (a.data() as Map<String, dynamic>)['date'];
                            final bDate =
                                (b.data() as Map<String, dynamic>)['date'];

                            final aTs =
                                aDate is Timestamp ? aDate.toDate() : DateTime(0);
                            final bTs =
                                bDate is Timestamp ? bDate.toDate() : DateTime(0);
                            return aTs.compareTo(bTs);
                          });

                        final now = DateTime.now();
                        final upcomingDocs = <QueryDocumentSnapshot>[];
                        final pastDocs = <QueryDocumentSnapshot>[];

                        for (final doc in sortedDocs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final ts = data['date'];
                          final date =
                              ts is Timestamp ? ts.toDate() : DateTime.now();
                          if (date.isBefore(now)) {
                            pastDocs.add(doc);
                          } else {
                            upcomingDocs.add(doc);
                          }
                        }

                        // Only keep upcoming reminders in session state.
                        final sessionReminders = upcomingDocs
                            .map((d) => d.data() as Map<String, dynamic>)
                            .toList();
                        PatientSession.instance.saveReminders(sessionReminders);

                        // Trigger cleanup of past items.
                        PatientSession.instance.cleanupExpiredReminders();

                        return ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                'Upcoming appointments',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (upcomingDocs.isEmpty)
                              const Card(
                                child: ListTile(
                                  leading: Icon(Icons.notifications),
                                  title: Text('No upcoming reminders'),
                                ),
                              )
                            else
                              ...upcomingDocs.map((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                final title = (data['title'] ?? '') as String;
                                final ts = data['date'];
                                final date = ts is Timestamp
                                    ? ts.toDate()
                                    : DateTime.now();
                                final isCompleted =
                                    (data['isCompleted'] ?? false) as bool;

                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.notifications_active,
                                      color: isCompleted
                                          ? Colors.grey
                                          : Colors.blueAccent,
                                    ),
                                    title: Text(
                                      title,
                                      style: TextStyle(
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    subtitle: Text(
                                      date.toLocal().toString(),
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                'Past appointments',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (pastDocs.isEmpty)
                              const Card(
                                child: ListTile(
                                  leading: Icon(Icons.history),
                                  title: Text('No past reminders'),
                                  subtitle: Text(
                                      'Past reminders are removed automatically.'),
                                ),
                              )
                            else
                              ...pastDocs.map((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                final title = (data['title'] ?? '') as String;
                                final ts = data['date'];
                                final date = ts is Timestamp
                                    ? ts.toDate()
                                    : DateTime.now();
                                final isCompleted =
                                    (data['isCompleted'] ?? false) as bool;

                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.notifications_off,
                                      color: Colors.grey.shade600,
                                    ),
                                    title: Text(
                                      title,
                                      style: TextStyle(
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    subtitle: Text(
                                        '${date.toLocal()} (will be removed)'),
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
