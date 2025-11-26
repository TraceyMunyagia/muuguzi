// lib/pages/patient_matched_caregiver_page.dart
// Updated to pull the top caregiver match from Firestore caregivers
// using the patient's saved preferences.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/patient_session.dart';

class PatientMatchedCaregiverPage extends StatefulWidget {
  const PatientMatchedCaregiverPage({super.key});

  @override
  State<PatientMatchedCaregiverPage> createState() =>
      _PatientMatchedCaregiverPageState();
}

class _PatientMatchedCaregiverPageState
    extends State<PatientMatchedCaregiverPage> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _bestMatch;

  @override
  void initState() {
    super.initState();
    _fetchMatch();
  }

  Future<void> _fetchMatch() async {
    final patientId = PatientSession.instance.patientId;
    if (patientId == null) {
      setState(() {
        _error = "Please log in again to see your caregiver match.";
        _bestMatch = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _bestMatch = null;
    });

    try {
      // Pull the stored preferences from Firestore (set on the Find Caregiver form)
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = "We could not find your preferences. Please submit them on "
              "the Find a Caregiver page first.";
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      final medicalNeeds =
          (data['medicalConditions'] ?? '').toString().trim();
      final location = (data['location'] ?? '').toString().trim();
      final gender = (data['preferredGender'] ?? '').toString().trim();
      final availability =
          (data['preferredAvailability'] ?? '').toString().trim();

      if (medicalNeeds.isEmpty ||
          location.isEmpty ||
          gender.isEmpty ||
          availability.isEmpty) {
        setState(() {
          _error = "Preferences look incomplete. Please update them on the "
              "Find a Caregiver page.";
        });
        return;
      }

      final payload = {
        "medical_needs": medicalNeeds,
        "location": location,
        "gender_preference": gender,
        "preferred_availability": availability,
      };

      final matches = await _matchCaregiversFromFirestore(payload);

      if (matches.isEmpty) {
        setState(() {
          _error = "No caregiver matches found in Firestore yet. "
              "Please try again in a moment.";
        });
        return;
      }

      final topMatch = matches.first;

      // Save a lightweight snapshot into the session for quick access elsewhere.
      PatientSession.instance.saveMatchedCaregiver(
        {
          'Name': topMatch['name'],
          'email': topMatch['email'],
          'phone': topMatch['phone'],
          'Location': topMatch['location'],
          'Qualifications':
              (topMatch['qualifications'] as List?)?.join(', ') ??
                  topMatch['qualifications'],
          'Availability': topMatch['availability'] ?? [],
          'Gender': [topMatch['gender'] ?? ''],
          'photoUrl': topMatch['photo_url'] ?? topMatch['photoUrl'],
        },
        (topMatch['id'] ?? topMatch['caregiver_id'] ?? '').toString(),
      );
      PatientSession.instance
          .saveMatchStatus(DateTime.now(), "active");

      setState(() {
        _bestMatch = topMatch;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to fetch match from backend: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Caregiver"),
        actions: [
          IconButton(
            onPressed: _loading ? null : _fetchMatch,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh from backend",
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(
                  message: _error!,
                  onRetry: _fetchMatch,
                )
              : _bestMatch == null
                  ? const Center(
                      child: Text(
                        "No caregiver matched yet.",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : _CaregiverDetails(match: _bestMatch!),
    );
  }
}

  Future<List<Map<String, dynamic>>> _matchCaregiversFromFirestore(
      Map<String, String> prefs) async {
    final snap =
        await FirebaseFirestore.instance.collection('caregivers').get();

    final String prefGender = prefs['gender_preference'] ?? '';
    final String prefAvailability = prefs['preferred_availability'] ?? '';
    final String prefLocation = prefs['location'] ?? '';
    final String medicalNeeds = prefs['medical_needs'] ?? '';

    final List<Map<String, dynamic>> results = [];

    for (final doc in snap.docs) {
      final data = doc.data();
      final availability =
          (data['Availability'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
      final genderList =
          (data['Gender'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
      final gender = genderList.isNotEmpty ? genderList.first : '';
      final location = (data['Location'] ?? '').toString();
      final qualificationsField = data['Qualifications'];
      final qualifications = qualificationsField is List
          ? qualificationsField.map((e) => e.toString()).toList()
          : (qualificationsField != null
              ? qualificationsField.toString().split(',')
              : <String>[]);

      double score = 0;
      if (prefAvailability.isNotEmpty &&
          availability
              .map((e) => e.toLowerCase())
              .contains(prefAvailability.toLowerCase())) {
        score += 2;
      }
      if (prefGender.isNotEmpty &&
          prefGender.toLowerCase() != 'other' &&
          gender.toLowerCase() == prefGender.toLowerCase()) {
        score += 2;
      }
      if (prefLocation.isNotEmpty &&
          location.toLowerCase().contains(prefLocation.toLowerCase())) {
        score += 1.5;
      }
      if (medicalNeeds.isNotEmpty) {
        final needs = medicalNeeds.toLowerCase();
        if (qualifications.any((q) => q.toLowerCase().contains(needs))) {
          score += 1;
        }
      }

      results.add({
        'id': doc.id,
        'name': data['Name'] ?? 'Unnamed',
        'email': data['email'],
        'phone': data['phone'],
        'location': location,
        'gender': gender,
        'availability': availability,
        'qualifications': qualifications,
        'photo_url': data['photoUrl'],
        'match_score': score,
      });
    }

    results.sort((a, b) {
      final aScore = (a['match_score'] as num?)?.toDouble() ?? 0;
      final bScore = (b['match_score'] as num?)?.toDouble() ?? 0;
      return bScore.compareTo(aScore);
    });

    return results;
  }

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Try again"),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaregiverDetails extends StatelessWidget {
  final Map<String, dynamic> match;

  const _CaregiverDetails({required this.match});

  @override
  Widget build(BuildContext context) {
    final name = match['name']?.toString() ?? 'Caregiver match';
    final email = match['email']?.toString() ?? '';
    final phone = match['phone']?.toString() ?? '';
    final location = match['location']?.toString() ?? '';
    final photoUrl =
        match['photo_url'] ?? match['photoUrl'];
    final availability =
        (match['availability'] as List<dynamic>?) ?? const [];
    final qualifications =
        (match['qualifications'] as List<dynamic>?) ?? const [];
    final gender = match['gender']?.toString() ?? '—';

    final score = match['score'] ?? match['match_score'];

    final session = PatientSession.instance;
    final matchTime = session.matchTimestamp;
    final status = session.matchStatus ?? "active";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (photoUrl != null && photoUrl.toString().isNotEmpty)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(photoUrl.toString()),
                )
              else
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              const SizedBox(height: 16),
              Text(
                name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Match Status: ${status[0].toUpperCase()}${status.substring(1)}",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.blueGrey,
                ),
              ),
              if (score != null)
                Text(
                  "Match score: ${score.toString()}",
                  style: const TextStyle(fontSize: 14),
                ),
              if (matchTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  "Matched on: ${matchTime.day}/${matchTime.month}/${matchTime.year}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const Divider(height: 32),
              if (email.isNotEmpty)
                _infoRow(Icons.email, "Email", email),
              if (phone.isNotEmpty)
                _infoRow(Icons.phone, "Phone", phone),
              if (location.isNotEmpty)
                _infoRow(Icons.location_on, "Location", location),
              if (qualifications.isNotEmpty)
                _infoRow(Icons.school, "Qualifications",
                    qualifications.join(", ")),
              _infoRow(Icons.person, "Gender", gender),
              if (availability.isNotEmpty)
                _infoRow(
                  Icons.access_time,
                  "Availability",
                  availability.join(", "),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
