import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'patient/home_page.dart';
import 'roles/splash_role_page.dart';
import 'patient/patient_auth_pages.dart';
import 'roles/caregiver_role_pages.dart' hide NursingHomeLoginPage;
import 'patient/prediction_page.dart';
import 'patient/caregiver_page.dart';
import 'patient/reminders_page.dart';
import 'patient/profile_page.dart';
import 'admin/admin_page.dart';
import 'admin/nursing_home_login_page.dart';

import 'patient/patient_prediction_history_page.dart';
import 'patient/patient_matched_caregiver_page.dart';

import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MuuguziApp());
}

class MuuguziApp extends StatelessWidget {
  const MuuguziApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);
    const Color lightBlue = Color(0xFFE6F2FF);

    return MaterialApp(
      title: 'Muuguzi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: lightBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightBlue,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // App starts at role selection
      initialRoute: '/',

      routes: {
        // ======================
        // Splash / role selection
        // ======================
        '/': (context) => const SplashRolePage(),

        // ======================
        // PATIENT ROUTES
        // ======================
        // Auth entry (screen that looks like your caregiver auth: Sign up / Log in)
        '/patient-auth': (context) => const PatientAuthChoicePage(),

        // New sign up & login pages
        '/patient-signup': (context) => const PatientSignupPage(),
        '/patient-login': (context) => const PatientLoginPage(),

        // Main patient home (bottom-nav shell, etc.)
        '/patient-home': (context) => const HomePage(),

        // Patient extra pages
        '/patient-predictions-history': (context) =>
            const PatientPredictionsHistoryPage(),
        '/patient-matched-caregiver': (context) =>
            const PatientMatchedCaregiverPage(),

        // Old alias if you still use '/patient' somewhere
        '/patient': (context) => const HomePage(),

        // ======================
        // CAREGIVER & NURSING HOME ROUTES
        // ======================
        '/caregiver-role': (context) => const CaregiverRoleSelectionPage(),
        '/caregiver-auth': (context) => const CaregiverAuthChoicePage(),
        '/caregiver-signup': (context) => const CaregiverSignupPage(),
        '/caregiver-login': (context) => const CaregiverLoginPage(),
        '/caregiver-home': (context) => const CaregiverHomeRoot(),

        // Nursing home login
        '/nursing-login': (context) => const NursingHomeLoginPage(),

        // Admin dashboard
        '/_admin': (context) => const AdminPage(),

        // ======================
        // OTHER PATIENT FEATURE PAGES
        // ======================
        '/prediction': (context) => const PredictionPage(),
        '/caregiver': (context) => const CaregiverPage(),
        '/reminders': (context) => const RemindersPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
