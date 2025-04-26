import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Set login status
  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required DateTime birthDate,
    required String gender,
  }) async {
    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Kullanıcı oluşturulamadı');
      }

      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
        'birthDate': birthDate,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Set login status
      await setLoggedIn(true);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Şifre çok zayıf');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Bu e-posta adresi zaten kullanımda');
      } else if (e.code == 'invalid-email') {
        throw Exception('Geçersiz e-posta adresi');
      } else {
        throw Exception('Kayıt işlemi başarısız: ${e.message}');
      }
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set login status
      await setLoggedIn(true);

      // Giriş bilgilerini kaydet
      final prefs = await SharedPreferences.getInstance();
      final shouldSave = prefs.getBool('saveLoginInfo') ?? false;
      
      if (shouldSave) {
        // E-postaları kaydet
        final savedEmails = prefs.getStringList('savedEmails') ?? [];
        if (!savedEmails.contains(email)) {
          savedEmails.add(email);
          await prefs.setStringList('savedEmails', savedEmails);
        }
        
        // Şifreyi güvenli bir şekilde kaydet (basit bir şifreleme ile)
        await prefs.setString('password_$email', _encryptPassword(password));
        
        await prefs.setString('lastUsedEmail', email);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Clear login status
      await setLoggedIn(false);
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? username,
    String? fullName,
    String? bio,
    String? phoneNumber,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (username != null) userData['username'] = username;
        if (fullName != null) userData['fullName'] = fullName;
        if (bio != null) userData['bio'] = bio;
        if (phoneNumber != null) userData['phoneNumber'] = phoneNumber;
        if (profileImageUrl != null) userData['profileImageUrl'] = profileImageUrl;
        if (bannerImageUrl != null) userData['bannerImageUrl'] = bannerImageUrl;
        if (email != null) userData['email'] = email;

        await _firestore.collection('users').doc(user.uid).update(userData);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data();
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Önce mevcut şifre ile yeniden doğrulama yap
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Şifreyi güncelle
      await user.updatePassword(newPassword);

      // Firestore'da şifre güncelleme zamanını kaydet
      await _firestore.collection('users').doc(user.uid).update({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Mevcut şifre yanlış');
      } else if (e.code == 'weak-password') {
        throw Exception('Yeni şifre çok zayıf');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Şifre değiştirmek için son zamanlarda giriş yapmanız gerekiyor');
      } else {
        throw Exception('Şifre değiştirilirken bir hata oluştu: ${e.message}');
      }
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<void> terminateSession(String deviceId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Firebase Cloud Functions üzerinden oturumu sonlandır
        await _firestore.collection('users').doc(user.uid).update({
          'activeSessions': FieldValue.arrayRemove([deviceId]),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get saved login emails
  Future<List<String>> getSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldSave = prefs.getBool('saveLoginInfo') ?? false;
    if (!shouldSave) return [];
    return prefs.getStringList('savedEmails') ?? [];
  }

  // Get saved password for email
  Future<String?> getSavedPassword(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final shouldSave = prefs.getBool('saveLoginInfo') ?? false;
    if (!shouldSave) return null;
    
    final encryptedPassword = prefs.getString('password_$email');
    if (encryptedPassword == null) return null;
    
    return _decryptPassword(encryptedPassword);
  }

  // Get last used email
  Future<String?> getLastUsedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldSave = prefs.getBool('saveLoginInfo') ?? false;
    if (!shouldSave) return null;
    return prefs.getString('lastUsedEmail');
  }

  // Remove saved email and its password
  Future<void> removeSavedEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmails = prefs.getStringList('savedEmails') ?? [];
    savedEmails.remove(email);
    await prefs.setStringList('savedEmails', savedEmails);
    
    // Şifreyi de sil
    await prefs.remove('password_$email');
    
    // Eğer silinen email son kullanılan email ise, onu da sil
    final lastUsedEmail = prefs.getString('lastUsedEmail');
    if (lastUsedEmail == email) {
      await prefs.remove('lastUsedEmail');
    }
  }

  // Basit şifreleme metodu (gerçek uygulamada daha güvenli bir yöntem kullanılmalı)
  String _encryptPassword(String password) {
    // Bu basit bir örnek, gerçek uygulamada daha güvenli bir şifreleme kullanılmalı
    return String.fromCharCodes(
      password.codeUnits.map((e) => e + 1),
    );
  }

  // Basit şifre çözme metodu
  String _decryptPassword(String encryptedPassword) {
    return String.fromCharCodes(
      encryptedPassword.codeUnits.map((e) => e - 1),
    );
  }

  // Tüm oturumları sonlandır
  Future<void> signOutAllSessions() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Kullanıcının tüm oturumlarını sonlandır
        await user.getIdToken(true); // Token'ı yenile
        await _auth.signOut(); // Mevcut oturumu sonlandır

        // Firestore'daki aktif oturumları temizle
        await _firestore.collection('users').doc(user.uid).update({
          'activeSessions': [],
          'lastSignOutTime': FieldValue.serverTimestamp(),
        });

        // SharedPreferences'daki login durumunu güncelle
        await setLoggedIn(false);
      }
    } catch (e) {
      rethrow;
    }
  }
} 