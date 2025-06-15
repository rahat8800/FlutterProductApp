import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Mock user storage (in a real app, this would be a database)
  static final Map<String, Map<String, dynamic>> _mockUsers = {};
  
  // Current user session
  User? _currentUser;
  bool _isLoggedIn = false;

  // File paths for persistence
  static const String _usersFileName = 'users.json';
  static const String _sessionFileName = 'session.json';

  // Initialize and load persisted data
  Future<void> initialize() async {
    await _loadUsers();
    await _loadSession();
  }

  // Load users from file
  Future<void> _loadUsers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_usersFileName');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> usersMap = json.decode(jsonString);
        
        _mockUsers.clear();
        usersMap.forEach((email, userData) {
          _mockUsers[email] = Map<String, dynamic>.from(userData);
        });
      }
    } catch (e) {
      // If file doesn't exist or is corrupted, start with empty users
      _mockUsers.clear();
    }
  }

  // Save users to file
  Future<void> _saveUsers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_usersFileName');
      
      final jsonString = json.encode(_mockUsers);
      await file.writeAsString(jsonString);
    } catch (e) {
      // Handle save error
      print('Error saving users: $e');
    }
  }

  // Load session from file
  Future<void> _loadSession() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_sessionFileName');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> sessionData = json.decode(jsonString);
        
        if (sessionData['isLoggedIn'] == true && sessionData['user'] != null) {
          _currentUser = User.fromJson(sessionData['user']);
          _isLoggedIn = true;
        }
      }
    } catch (e) {
      // If file doesn't exist or is corrupted, start with no session
      _currentUser = null;
      _isLoggedIn = false;
    }
  }

  // Save session to file
  Future<void> _saveSession() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_sessionFileName');
      
      final sessionData = {
        'isLoggedIn': _isLoggedIn,
        'user': _currentUser?.toJson(),
      };
      
      final jsonString = json.encode(sessionData);
      await file.writeAsString(jsonString);
    } catch (e) {
      // Handle save error
      print('Error saving session: $e');
    }
  }

  Future<bool> register(String email, String password, String name) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if user already exists
    if (_mockUsers.containsKey(email)) {
      throw Exception('Email already exists');
    }

    // Validate password strength
    if (password.length < 6) {
      throw Exception('Password is too weak');
    }

    // Create new user
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
    );

    // Store user data
    _mockUsers[email] = {
      'user': user.toJson(),
      'password': password, // In real app, this would be hashed
    };

    // Save to persistent storage
    await _saveUsers();

    return true;
  }

  Future<User> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if user exists
    if (!_mockUsers.containsKey(email)) {
      throw Exception('Invalid email or password');
    }

    final userData = _mockUsers[email]!;
    
    // Check password
    if (userData['password'] != password) {
      throw Exception('Invalid email or password');
    }

    final user = User.fromJson(userData['user']);
    
    // Set current session
    _currentUser = user;
    _isLoggedIn = true;
    
    // Save session to persistent storage
    await _saveSession();
    
    return user;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    
    // Clear session from persistent storage
    await _saveSession();
  }

  bool get isLoggedIn => _isLoggedIn;

  User? get currentUser => _currentUser;

  // Update user data in mock storage
  void updateUserData(User updatedUser) {
    if (_currentUser != null) {
      _mockUsers[_currentUser!.email] = {
        'user': updatedUser.toJson(),
        'password': _mockUsers[_currentUser!.email]!['password'],
      };
      _currentUser = updatedUser;
      
      // Save updated data
      _saveUsers();
      _saveSession();
    }
  }
} 