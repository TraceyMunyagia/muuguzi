// lib/services/admin_session.dart

/// Simple in-memory session for the currently logged-in admin.
/// Populated after a successful login, and used by AdminPage.
class AdminSession {
  AdminSession._internal();

  static final AdminSession instance = AdminSession._internal();

  /// Firestore document ID of this admin in the 'admin' collection.
  String? adminId;

  /// Admin email.
  String? email;

  void clear() {
    adminId = null;
    email = null;
  }

  void logout() {
    adminId = null;
    email = null;
  }
}
