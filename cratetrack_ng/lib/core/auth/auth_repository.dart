import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A locally authenticated operator/business account.
class AuthUser {
  final String businessName;
  final String email;
  const AuthUser({required this.businessName, required this.email});
}

/// Thrown when a sign-up or login attempt fails validation.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

/// Local-only authentication backed by Hive. There is no backend: credentials
/// are stored on-device, passwords are never kept in plain text, and a small
/// session box records which account (if any) is currently logged in so
/// returning users can skip straight to the dashboard.
class AuthRepository {
  static const _usersBox = 'auth_users_box';
  static const _sessionBox = 'auth_session_box';
  static const _sessionKey = 'current_user_email';

  Box? _users;
  Box? _session;

  /// Initializes Hive storage. Pass [testDirectoryPath] in tests to avoid
  /// depending on the path_provider platform channel.
  Future<void> init({String? testDirectoryPath}) async {
    if (testDirectoryPath != null) {
      Hive.init(testDirectoryPath);
    } else {
      await Hive.initFlutter();
    }
    _users = await Hive.openBox(_usersBox);
    _session = await Hive.openBox(_sessionBox);
  }

  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  /// Whether a returning user is currently logged in on this device.
  bool isLoggedIn() => _session!.get(_sessionKey) != null;

  /// The currently logged-in account, or null when signed out.
  AuthUser? get currentUser {
    final email = _session!.get(_sessionKey) as String?;
    if (email == null) return null;
    final raw = _users!.get(email);
    if (raw == null) return null;
    final map = Map<dynamic, dynamic>.from(raw as Map);
    return AuthUser(businessName: map['businessName'] as String, email: email);
  }

  /// Creates a new local account and logs it in. Throws [AuthException] on
  /// invalid input or a duplicate email.
  Future<AuthUser> signUp({
    required String businessName,
    required String email,
    required String password,
  }) async {
    final trimmedName = businessName.trim();
    final normalizedEmail = _normalizeEmail(email);

    if (trimmedName.isEmpty) {
      throw const AuthException('Enter your operator or business name');
    }
    if (!_looksLikeEmail(normalizedEmail)) {
      throw const AuthException('Enter a valid email address');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }
    if (_users!.containsKey(normalizedEmail)) {
      throw const AuthException('An account with this email already exists');
    }

    await _users!.put(normalizedEmail, {
      'businessName': trimmedName,
      'passwordHash': _hash(password),
    });
    await _session!.put(_sessionKey, normalizedEmail);
    return AuthUser(businessName: trimmedName, email: normalizedEmail);
  }

  /// Validates credentials against the locally stored account and, on
  /// success, marks the user as logged in. Throws [AuthException] otherwise.
  Future<AuthUser> logIn({required String email, required String password}) async {
    final normalizedEmail = _normalizeEmail(email);
    final raw = _users!.get(normalizedEmail);
    if (raw == null) {
      throw const AuthException('No account found for this email');
    }
    final map = Map<dynamic, dynamic>.from(raw as Map);
    if (map['passwordHash'] != _hash(password)) {
      throw const AuthException('Incorrect password');
    }
    await _session!.put(_sessionKey, normalizedEmail);
    return AuthUser(businessName: map['businessName'] as String, email: normalizedEmail);
  }

  /// Clears the local session, keeping the stored account for next login.
  Future<void> logOut() async {
    await _session!.delete(_sessionKey);
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}
