class UserSession {
  // Static variables to hold data globally
  static String? _userName;
  static String? _userEmail;

  // Setters
  static void setUser(String name, String email) {
    _userName = name;
    _userEmail = email;
  }

  // Getters (with fallback if empty)
  static String get name => _userName ?? "Guest User";
  static String get email => _userEmail ?? "guest@agrisync.app";

  // Clear session (for Logout)
  static void clear() {
    _userName = null;
    _userEmail = null;
  }
}
