
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientSession {
  PatientSession._private();
  static final PatientSession instance = PatientSession._private();

  String? patientId;
  String? email;
  String? name;
  String? phone;
  String? photoUrl;


  Map<String, dynamic> predictionInput = {};

  void savePredictionInput(Map<String, dynamic> data) {
    predictionInput = data;
  }

  void clearPredictionInput() {
    predictionInput = {};
  }

 
  String? matchedCaregiverId;
  String? caregiverName;
  String? caregiverEmail;
  String? caregiverPhone;
  String? caregiverLocation;
  String? caregiverPhoto;
  String? caregiverQualification;
  List<String> caregiverAvailability = [];
  String? caregiverGender;

  void saveMatchedCaregiver(Map<String, dynamic> data, String caregiverId) {
    matchedCaregiverId = caregiverId;

    caregiverName = data['Name'] as String?;
    caregiverEmail = data['email'] as String?;
    caregiverPhone = data['phone'] as String?;
    caregiverLocation = data['Location'] as String?;
    caregiverPhoto = data['photoUrl'] as String?;
    caregiverQualification = data['Qualifications'] as String?;

    if (data['Availability'] != null) {
      caregiverAvailability = List<String>.from(data['Availability'] as List);
    }

    if (data['Gender'] != null &&
        data['Gender'] is List &&
        (data['Gender'] as List).isNotEmpty) {
      caregiverGender = (data['Gender'] as List).first as String?;
    }
  }

  void clearMatchedCaregiver() {
    matchedCaregiverId = null;
    caregiverName = null;
    caregiverEmail = null;
    caregiverPhone = null;
    caregiverLocation = null;
    caregiverPhoto = null;
    caregiverQualification = null;
    caregiverAvailability = [];
    caregiverGender = null;
  }

  DateTime? matchTimestamp;
  String? matchStatus; 

  void saveMatchStatus(DateTime timestamp, String status) {
    matchTimestamp = timestamp;
    matchStatus = status;
  }

  void clearMatchStatus() {
    matchTimestamp = null;
    matchStatus = null;
  }

  List<Map<String, dynamic>> reminders = [];

  void saveReminders(List<Map<String, dynamic>> list) {
    reminders = list;
  }

  void clearReminders() {
    reminders = [];
  }

  bool _cleaningReminders = false;

 
  Future<void> cleanupExpiredReminders() async {
    if (patientId == null || _cleaningReminders) return;

    _cleaningReminders = true;
    try {
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
    } finally {
      _cleaningReminders = false;
    }
  }

 
  Future<bool> login(String emailInput, String passwordInput) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('patients')
        .where('email', isEqualTo: emailInput.trim())
        .where('password', isEqualTo: passwordInput.trim())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // invalid credentials
      return false;
    }

    final doc = snapshot.docs.first;
    final data = doc.data();

    // Fill session fields
    patientId = doc.id;
    email = data['email'] as String?;
    name = data['name'] as String?;
    phone = data['phone'] as String?;
    photoUrl = data['photoURL'] as String?;

    // If the patient document already stores a matchedCaregiverId,
    // you can store it here for later use.
    if (data['matchedCaregiverId'] != null) {
      matchedCaregiverId = data['matchedCaregiverId'] as String?;
    }

    return true;
  }

  
  void logout() {
    clearAll();
  }

 
  void clearAll() {
    patientId = null;
    email = null;
    name = null;
    phone = null;
    photoUrl = null;

    // prediction
    predictionInput = {};

    // matched caregiver
    clearMatchedCaregiver();

    // match status
    clearMatchStatus();

    // reminders
    reminders = [];
  }
}
