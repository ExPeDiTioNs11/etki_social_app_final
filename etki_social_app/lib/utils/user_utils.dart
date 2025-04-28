import 'package:etki_social_app/services/auth_service.dart';

class UserUtils {
  static final _authService = AuthService();

  static String getCurrentUser() {
    final user = _authService.currentUser;
    return user?.uid ?? '';
  }
} 