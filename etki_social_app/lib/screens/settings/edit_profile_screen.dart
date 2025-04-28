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
  String? _selectedCity;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  double _completionPercentage = 0.0;

  // Türkiye şehirleri listesi
  final List<String> _cities = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya', 'Artvin',
    'Aydın', 'Balıkesir', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale',
    'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum',
    'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', 'Isparta', 'Mersin',
    'İstanbul', 'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir', 'Kocaeli',
    'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin', 'Muğla', 'Muş', 'Nevşehir',
    'Niğde', 'Ordu', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Tekirdağ', 'Tokat',
    'Trabzon', 'Tunceli', 'Şanlıurfa', 'Uşak', 'Van', 'Yozgat', 'Zonguldak', 'Aksaray', 'Bayburt',
    'Karaman', 'Kırıkkale', 'Batman', 'Şırnak', 'Bartın', 'Ardahan', 'Iğdır', 'Yalova', 'Karabük',
    'Kilis', 'Osmaniye', 'Düzce'
  ];

  // Calculate profile completion percentage
  double _calculateCompletionPercentage() {
    if (_userData == null) return 0.0;

    int totalFields = 5; // username, fullName, bio, phoneNumber, city
    int completedFields = 0;

    if (_usernameController.text.isNotEmpty) completedFields++;
    if (_fullNameController.text.isNotEmpty) completedFields++;
    if (_bioController.text.isNotEmpty) completedFields++;
    if (_phoneController.text.isNotEmpty) completedFields++;
    if (_selectedCity != null) completedFields++;

    return (completedFields / totalFields) * 100;
  }

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
          _selectedCity = userData?['city'];
          _completionPercentage = _calculateCompletionPercentage();
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
          city: _selectedCity,
        );

        setState(() {
          _completionPercentage = _calculateCompletionPercentage();
        });

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
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
                    const SizedBox(height: 16),
                    // City Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          hint: Text('Şehir Seçin', style: TextStyle(color: AppColors.textSecondary)),
                          icon: Icon(Icons.location_city, color: AppColors.primary),
                          items: _cities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city, style: TextStyle(color: AppColors.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCity = newValue;
                              _completionPercentage = _calculateCompletionPercentage();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Profile Completion Indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profil Tamamlanma',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getCompletionColor(_completionPercentage).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_completionPercentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getCompletionColor(_completionPercentage),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeInOut,
                              tween: Tween<double>(
                                begin: 0,
                                end: _completionPercentage / 100,
                              ),
                              builder: (context, value, _) => LinearProgressIndicator(
                                value: value,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getCompletionColor(_completionPercentage),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getCompletionMessage(_completionPercentage),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getCompletionColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getCompletionMessage(double percentage) {
    if (percentage >= 80) return 'Harika! Profiliniz neredeyse tamamen hazır.';
    if (percentage >= 50) return 'İyi gidiyorsunuz! Birkaç alan daha doldurun.';
    return 'Profilinizi tamamlamaya başlayın.';
  }
} 