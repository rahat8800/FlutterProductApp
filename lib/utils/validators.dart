import 'package:form_field_validator/form_field_validator.dart';

class Validators {
  static final emailValidator = MultiValidator([
    RequiredValidator(errorText: 'Email is required'),
    EmailValidator(errorText: 'Please enter a valid email'),
  ]);

  static final passwordValidator = MultiValidator([
    RequiredValidator(errorText: 'Password is required'),
    MinLengthValidator(8, errorText: 'Password must be at least 8 characters'),
    PatternValidator(
      r'(?=.*[a-z])',
      errorText: 'Password must contain at least one lowercase letter',
    ),
    PatternValidator(
      r'(?=.*[A-Z])',
      errorText: 'Password must contain at least one uppercase letter',
    ),
    PatternValidator(
      r'(?=.*\d)',
      errorText: 'Password must contain at least one number',
    ),
    PatternValidator(
      r'(?=.*[!@#$%^&*(),.?":{}|<>])',
      errorText: 'Password must contain at least one special character',
    ),
  ]);

  static final simplePasswordValidator = MultiValidator([
    RequiredValidator(errorText: 'Password is required'),
    MinLengthValidator(6, errorText: 'Password must be at least 6 characters'),
  ]);

  static final nameValidator = MultiValidator([
    RequiredValidator(errorText: 'Name is required'),
    MinLengthValidator(2, errorText: 'Name must be at least 2 characters'),
    PatternValidator(
      r'^[a-zA-Z\s]+$',
      errorText: 'Name can only contain letters and spaces',
    ),
  ]);

  static String? confirmPasswordValidator(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? sanitizeInputValidator(String? value) {
    if (value == null) return null;
    
    final dangerousPattern = RegExp(r'[<>"\']');
    if (dangerousPattern.hasMatch(value)) {
      return 'Input contains invalid characters';
    }
    
    return null;
  }

  static final phoneValidator = MultiValidator([
    RequiredValidator(errorText: 'Phone number is required'),
    PatternValidator(
      r'^\+?[\d\s\-\(\)]+$',
      errorText: 'Please enter a valid phone number',
    ),
  ]);

  static final usernameValidator = MultiValidator([
    RequiredValidator(errorText: 'Username is required'),
    MinLengthValidator(3, errorText: 'Username must be at least 3 characters'),
    MaxLengthValidator(20, errorText: 'Username must be less than 20 characters'),
    PatternValidator(
      r'^[a-zA-Z0-9_]+$',
      errorText: 'Username can only contain letters, numbers, and underscores',
    ),
  ]);
} 