// lib/pages/caregiver_home_root.dart

import 'package:flutter/material.dart';

import 'caregiver_patients_page.dart';
import 'caregiver_reminders_page.dart';
import 'caregiver_profile_page.dart';

class CaregiverHomeRoot extends StatefulWidget {
  const CaregiverHomeRoot({super.key});

  @override
  State<CaregiverHomeRoot> createState() => _CaregiverHomeRootState();
}

class _CaregiverHomeRootState extends State<CaregiverHomeRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    final pages = [
      const _CaregiverHomePage(),
      const CaregiverPatientsPage(),
      const CaregiverRemindersPage(),
      const CaregiverProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muuguzi - Caregiver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'View reminder history',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CaregiverRemindersPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patient'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CaregiverHomePage extends StatelessWidget {
  const _CaregiverHomePage();

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
                    child: Icon(Icons.medical_information, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Welcome caregiver! View your patient and manage reminders.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.people, color: primaryBlue),
              title: Text('Patient'),
              subtitle: Text('View and manage your matched patient'),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.calendar_month, color: primaryBlue),
              title: Text('Reminders'),
              subtitle: Text('Check upcoming appointments'),
            ),
          ),
        ],
      ),
    );
  }
}
