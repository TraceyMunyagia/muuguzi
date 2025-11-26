import 'package:flutter/material.dart';
import 'package:muuguzi_app/patient/caregiver_page.dart';
import 'reminders_page.dart';
import 'prediction_page.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muuguzi_app/services/patient_session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeDashboard(),
    PredictionPage(),
    CaregiverPage(),
    RemindersPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muuguzi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'View reminders',
            onPressed: () => Navigator.pushNamed(context, '/reminders'),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Prediction',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Caregivers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);
    const Color lightBlue = Color(0xFFE6F2FF);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: lightBlue,
                    child: Icon(Icons.health_and_safety, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '''Welcome to Muuguzi!
Track dementia care, predict survival levels, and find the right caregiver.''',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.analytics,
                  label: 'Predict Survival',
                  color: primaryBlue,
                  onTap: () => Navigator.pushNamed(context, '/prediction'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.people,
                  label: 'Find Caregiver',
                  color: primaryBlue,
                  onTap: () => Navigator.pushNamed(context, '/caregiver'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Upcoming Reminders',
            onViewAll: () => Navigator.pushNamed(context, '/reminders'),
          ),
          const SizedBox(height: 8),
          const _UpcomingRemindersList(),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color lightBlue = Color(0xFFE6F2FF);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        color: lightBlue,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingRemindersList extends StatelessWidget {
  const _UpcomingRemindersList();

  @override
  Widget build(BuildContext context) {
    final patientId = PatientSession.instance.patientId;

    if (patientId == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.notifications_off),
          title: const Text('Please log in to see your reminders'),
          trailing: IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.pushNamed(context, '/reminders'),
          ),
        ),
      );
    }

    // Clean up any expired reminders whenever the home dashboard is shown.
    PatientSession.instance.cleanupExpiredReminders();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Reminders')
          .where('patientId', isEqualTo: patientId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Unable to load reminders'),
              subtitle: Text(
                'Please try again soon.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('No upcoming reminders'),
              subtitle:
                  const Text('Add your appointments in the Reminders tab.'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => Navigator.pushNamed(context, '/reminders'),
              ),
            ),
          );
        }

        // Sort client-side so we do not rely on composite Firestore indexes.
        final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs)
          ..sort((a, b) {
            final aDate = (a.data() as Map<String, dynamic>)['date'];
            final bDate = (b.data() as Map<String, dynamic>)['date'];

            final aTs = aDate is Timestamp ? aDate.toDate() : DateTime(0);
            final bTs = bDate is Timestamp ? bDate.toDate() : DateTime(0);
            return aTs.compareTo(bTs);
          });

        // Take the first 5 upcoming reminders
        final limitedDocs = docs.take(5).toList();

        return Column(
          children: limitedDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString();
            final timestamp = data['date'];
            DateTime? date;
            if (timestamp is Timestamp) {
              date = timestamp.toDate();
            }
            final isCompleted = (data['isCompleted'] ?? false) as bool;

            final dateText = date != null
                ? '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                : 'Scheduled';

            return Card(
              child: ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: isCompleted ? Colors.grey : Colors.blueAccent,
                ),
                title: Text(
                  title.isEmpty ? 'Reminder' : title,
                  style: TextStyle(
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Text(dateText),
                onTap: () => Navigator.pushNamed(context, '/reminders'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'View all',
              style: TextStyle(color: primaryBlue),
            ),
          ),
      ],
    );
  }
}
