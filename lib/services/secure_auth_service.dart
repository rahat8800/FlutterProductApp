import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user.dart';

class SecureAuthService {
  static final SecureAuthService _instance = SecureAuthService._internal();
  factory SecureAuthService() => _instance;
  SecureAuthService._internal();

  // Secure storage for sensitive data
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // User data storage (in production, this would be a secure database)
  static final Map<String, Map<String, dynamic>> _users = {};
  
  // Session management
  User? _currentUser;
  bool _isLoggedIn = false;

  // Rate limiting and security
  static final Map<String, LoginAttempt> _loginAttempts = {};
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const Duration _attemptResetDuration = Duration(minutes: 30);

  // Biometric authentication
  bool _biometricEnabled = false;

  // Initialize the service
  Future<void> initialize() async {
    await _loadUsers();
    await _loadSession();
    await _checkBiometricAvailability();
  }

  // Check if biometric authentication is available
  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      _biometricEnabled = isAvailable && isDeviceSupported;
    } catch (e) {
      _biometricEnabled = false;
    }
  }

  // Load users from secure storage
  Future<void> _loadUsers() async {
    try {
      final usersJson = await _secureStorage.read(key: 'users');
      if (usersJson != null) {
        final Map<String, dynamic> usersMap = json.decode(usersJson);
        _users.clear();
        usersMap.forEach((email, userData) {
          _users[email] = Map<String, dynamic>.from(userData);
        });
      }
    } catch (e) {
      _users.clear();
    }
  }

  // Save users to secure storage
  Future<void> _saveUsers() async {
    try {
      final jsonString = json.encode(_users);
      await _secureStorage.write(key: 'users', value: jsonString);
    } catch (e) {
      throw Exception('Failed to save user data securely');
    }
  }

  // Load session from secure storage
  Future<void> _loadSession() async {
    try {
      final sessionJson = await _secureStorage.read(key: 'session');
      if (sessionJson != null) {
        final Map<String, dynamic> sessionData = json.decode(sessionJson);
        
        // Check if session is still valid
        final sessionExpiry = DateTime.parse(sessionData['expiresAt']);
        if (DateTime.now().isBefore(sessionExpiry)) {
          _currentUser = User.fromJson(sessionData['user']);
          _isLoggedIn = true;
        } else {
          // Session expired, clear it
          await _secureStorage.delete(key: 'session');
        }
      }
    } catch (e) {
      _currentUser = null;
      _isLoggedIn = false;
    }
  }

  // Save session to secure storage with expiration
  Future<void> _saveSession() async {
    try {
      final sessionData = {
        'isLoggedIn': _isLoggedIn,
        'user': _currentUser?.toJson(),
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      final jsonString = json.encode(sessionData);
      await _secureStorage.write(key: 'session', value: jsonString);
    } catch (e) {
      throw Exception('Failed to save session securely');
    }
  }

  // Hash password using bcrypt
  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  // Verify password against hash
  bool _verifyPassword(String password, String hash) {
    return BCrypt.checkpw(password, hash);
  }

  // Generate secure random salt
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  // Hash email for rate limiting (privacy-preserving)
  String _hashEmail(String email) {
    final bytes = utf8.encode(email.toLowerCase().trim());
    return sha256.convert(bytes).toString();
  }

  // Check if account is locked
  bool _isAccountLocked(String email) {
    final hashedEmail = _hashEmail(email);
    final attempt = _loginAttempts[hashedEmail];
    
    if (attempt == null) return false;
    
    // Check if lockout period has passed
    if (DateTime.now().difference(attempt.lastAttempt) > _lockoutDuration) {
      _loginAttempts.remove(hashedEmail);
      return false;
    }
    
    return attempt.failedAttempts >= _maxLoginAttempts;
  }

  // Record failed login attempt
  void _recordFailedAttempt(String email) {
    final hashedEmail = _hashEmail(email);
    final now = DateTime.now();
    
    if (_loginAttempts.containsKey(hashedEmail)) {
      final attempt = _loginAttempts[hashedEmail]!;
      
      // Reset attempts if enough time has passed
      if (now.difference(attempt.lastAttempt) > _attemptResetDuration) {
        attempt.failedAttempts = 1;
      } else {
        attempt.failedAttempts++;
      }
      attempt.lastAttempt = now;
    } else {
      _loginAttempts[hashedEmail] = LoginAttempt(
        failedAttempts: 1,
        lastAttempt: now,
      );
    }
  }

  // Record successful login
  void _recordSuccessfulLogin(String email) {
    final hashedEmail = _hashEmail(email);
    _loginAttempts.remove(hashedEmail);
  }

  // Sanitize input
  String _sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'[<>"\']'), '');
  }

  // Register new user with enhanced security
  Future<bool> register(String email, String password, String name) async {
    // Sanitize inputs
    final sanitizedEmail = _sanitizeInput(email).toLowerCase();
    final sanitizedName = _sanitizeInput(name);
    
    // Validate inputs
    if (sanitizedEmail.isEmpty || sanitizedName.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }
    
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(sanitizedEmail)) {
      throw Exception('Invalid email format');
    }
    
    // Check if user already exists
    if (_users.containsKey(sanitizedEmail)) {
      throw Exception('Email already exists');
    }

    // Create new user with hashed password
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: sanitizedEmail,
      name: sanitizedName,
    );

    // Store user data with hashed password
    _users[sanitizedEmail] = {
      'user': user.toJson(),
      'passwordHash': _hashPassword(password),
      'salt': _generateSalt(),
      'createdAt': DateTime.now().toIso8601String(),
      'lastLogin': null,
    };

    // Save to secure storage
    await _saveUsers();
    return true;
  }

  // Login with enhanced security
  Future<User> login(String email, String password) async {
    // Sanitize email
    final sanitizedEmail = _sanitizeInput(email).toLowerCase();
    
    // Check if account is locked
    if (_isAccountLocked(sanitizedEmail)) {
      final hashedEmail = _hashEmail(sanitizedEmail);
      final attempt = _loginAttempts[hashedEmail]!;
      final remainingTime = _lockoutDuration - DateTime.now().difference(attempt.lastAttempt);
      throw Exception('Account is locked. Try again in ${remainingTime.inMinutes} minutes');
    }

    // Check if user exists
    if (!_users.containsKey(sanitizedEmail)) {
      _recordFailedAttempt(sanitizedEmail);
      throw Exception('Invalid email or password');
    }

    final userData = _users[sanitizedEmail]!;
    
    // Verify password
    if (!_verifyPassword(password, userData['passwordHash'])) {
      _recordFailedAttempt(sanitizedEmail);
      throw Exception('Invalid email or password');
    }

    // Login successful
    _recordSuccessfulLogin(sanitizedEmail);
    
    final user = User.fromJson(userData['user']);
    
    // Update last login
    userData['lastLogin'] = DateTime.now().toIso8601String();
    await _saveUsers();
    
    // Set current session
    _currentUser = user;
    _isLoggedIn = true;
    
    // Save session to secure storage
    await _saveSession();
    
    return user;
  }

  // Biometric authentication
  Future<User?> authenticateWithBiometrics() async {
    if (!_biometricEnabled) {
      throw Exception('Biometric authentication not available');
    }

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated && _currentUser != null) {
        return _currentUser;
      }
    } catch (e) {
      throw Exception('Biometric authentication failed');
    }

    return null;
  }

  // Enable biometric authentication for current user
  Future<bool> enableBiometric() async {
    if (!_biometricEnabled || _currentUser == null) {
      return false;
    }

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await _secureStorage.write(
          key: 'biometric_enabled_${_currentUser!.email}',
          value: 'true',
        );
        return true;
      }
    } catch (e) {
      return false;
    }

    return false;
  }

  // Check if biometric is enabled for user
  Future<bool> isBiometricEnabled(String email) async {
    final enabled = await _secureStorage.read(
      key: 'biometric_enabled_$email',
    );
    return enabled == 'true';
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    
    // Clear session from secure storage
    await _secureStorage.delete(key: 'session');
  }

  // Change password with security validation
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    final userData = _users[_currentUser!.email]!;
    
    // Verify current password
    if (!_verifyPassword(currentPassword, userData['passwordHash'])) {
      throw Exception('Current password is incorrect');
    }

    // Update password hash
    userData['passwordHash'] = _hashPassword(newPassword);
    userData['salt'] = _generateSalt();
    
    await _saveUsers();
    return true;
  }

  // Getter methods
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  bool get biometricEnabled => _biometricEnabled;

  // Update user data
  void updateUserData(User updatedUser) {
    if (_currentUser != null) {
      _users[_currentUser!.email] = {
        ..._users[_currentUser!.email]!,
        'user': updatedUser.toJson(),
      };
      _currentUser = updatedUser;
      
      _saveUsers();
      _saveSession();
    }
  }
}

// Class to track login attempts
class LoginAttempt {
  int failedAttempts;
  DateTime lastAttempt;

  LoginAttempt({
    required this.failedAttempts,
    required this.lastAttempt,
  });
} 