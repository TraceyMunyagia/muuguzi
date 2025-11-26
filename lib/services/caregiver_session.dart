// lib/services/caregiver_session.dart

class CaregiverSession {
  CaregiverSession._privateConstructor();
  static final CaregiverSession instance =
      CaregiverSession._privateConstructor();

  // ------------------------------
  // CAREGIVER LOGIN SESSION
  // ------------------------------
  String? caregiverId;
  String? email;
  String? name;
  String? phone;
  String? location;
  String? gender;
  String? qualifications; // string or comma separated
  List<String> availability = [];

  String? photoUrl;

  // ------------------------------
  // MATCHED PATIENT SESSION
  // ------------------------------
  String? matchedPatientId;
  String? patientName;
  String? patientEmail;
  String? patientPhone;

  // ------------------------------
  // REMINDERS SESSION
  // ------------------------------
  String? remindersPatientId;
  List<Map<String, dynamic>> reminders = [];

  // ------------------------------
  // CLEAR SESSION (LOGOUT)
  // ------------------------------
  void clear() {
    caregiverId = null;
    email = null;
    name = null;
    phone = null;
    location = null;
    gender = null;
    qualifications = null;
    availability = [];
    photoUrl = null;

    matchedPatientId = null;
    patientName = null;
    patientEmail = null;
    patientPhone = null;

    remindersPatientId = null;
    reminders = [];
  }
   void logout() {
    caregiverId = null;
    email = null;
    name = null;
    phone = null;
    photoUrl = null;
    // clear other fields here if needed
  }

}
