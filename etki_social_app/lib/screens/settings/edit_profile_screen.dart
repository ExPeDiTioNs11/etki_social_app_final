import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:etki_social_app/services/auth_service.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/widgets/custom_text_field.dart';
import 'package:etki_social_app/widgets/custom_button.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userData = userData;
          _usernameController.text = userData?['username'] ?? '';
          _fullNameController.text = userData?['fullName'] ?? '';
          _bioController.text = userData?['bio'] ?? '';
          _phoneController.text = userData?['phoneNumber'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil bilgileri yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.updateUserProfile(
          username: _usernameController.text,
          fullName: _fullNameController.text,
          bio: _bioController.text,
          phoneNumber: _phoneController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profil güncellenirken bir hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Username
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Kullanıcı Adı',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kullanıcı adı zorunludur';
                        }
                        if (value.length < 3) {
                          return 'Kullanıcı adı en az 3 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Full Name
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Ad Soyad',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    // Bio
                    CustomTextField(
                      controller: _bioController,
                      label: 'Hakkımda',
                      prefixIcon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Phone Number
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Telefon Numarası',
                      prefixIcon: Icons.phone_outlined,
                      isPhoneNumber: true,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final phoneRegex = RegExp(r'^[0-9]{10}$');
                          if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''))) {
                            return 'Geçerli bir telefon numarası giriniz';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Save Button
                    CustomButton(
                      text: 'Kaydet',
                      onPressed: _isLoading ? null : _updateProfile,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 