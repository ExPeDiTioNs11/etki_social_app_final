import 'package:flutter/material.dart';
import 'package:etki_social_app/services/auth_service.dart';
import 'package:etki_social_app/utils/validators.dart';
import 'package:etki_social_app/widgets/custom_text_field.dart';
import 'package:etki_social_app/widgets/custom_button.dart';
import 'package:etki_social_app/widgets/date_picker_field.dart';
import 'package:etki_social_app/widgets/gender_selector.dart';
import 'package:etki_social_app/utils/theme.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGender = '';

  bool _isLoading = false;
  int _currentStep = 0;
  final int _totalSteps = 3;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Step titles
  final List<String> _stepTitles = [
    'Kişisel Bilgiler',
    'Hesap Bilgileri',
    'Doğrulama'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();

    // Add listeners to text controllers
    _emailController.addListener(_updateFormState);
    _passwordController.addListener(_updateFormState);
    _confirmPasswordController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

      setState(() => _isLoading = true);

    try {
      // Convert birth date string to DateTime
      final dateParts = _birthDateController.text.split('.');
      if (dateParts.length != 3) {
        throw Exception('Geçersiz tarih formatı. Lütfen GG.AA.YYYY formatında giriniz.');
      }
      
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      
      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900 || year > DateTime.now().year) {
        throw Exception('Geçersiz tarih değeri. Lütfen geçerli bir tarih giriniz.');
      }
      
      final birthDate = DateTime(year, month, day);

      // Register user with Firebase
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
        phoneNumber: _phoneController.text,
        birthDate: birthDate,
        gender: _selectedGender,
      );

      // Navigate to home screen on success
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('email-already-in-use')
                  ? 'Bu email adresi zaten kullanımda'
                  : e.toString().contains('weak-password')
                      ? 'Şifre çok zayıf'
                      : e.toString().contains('invalid-email')
                          ? 'Geçersiz e-posta adresi'
                          : e.toString().contains('invalid date format')
                              ? 'Geçersiz tarih formatı. Lütfen GG.AA.YYYY formatında giriniz.'
                              : e.toString(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _animationController.reset();
      setState(() => _currentStep++);
      _animationController.forward();
    } else {
      _register();
  }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      setState(() => _currentStep--);
      _animationController.forward();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _usernameController.text.isNotEmpty &&
            _birthDateController.text.isNotEmpty &&
            _selectedGender.isNotEmpty &&
            _phoneController.text.isNotEmpty;
      case 1:
        return _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text &&
            Validators.validateEmail(_emailController.text) == null &&
            Validators.validatePassword(_passwordController.text) == null;
      case 2:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Bize Katıl',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
            child: Column(
              children: [
              // Modern Step Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                  child: Column(
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        _totalSteps,
                        (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index <= _currentStep
                                  ? AppTheme.secondaryColor
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      ),
                      const SizedBox(height: 16),
                    Text(
                      _stepTitles[_currentStep],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content with Animation
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (_currentStep == 0) ...[
                            _buildAnimatedFormField(
                              CustomTextField(
                                controller: _usernameController,
                                label: 'Kullanıcı Adı',
                                validator: Validators.validateUsername,
                                prefixIcon: Icons.person_outline,
                              ),
                      ),
                      const SizedBox(height: 16),
                            _buildAnimatedFormField(
                              CustomTextField(
                        controller: _phoneController,
                                label: 'Telefon Numarası',
                                isPhoneNumber: true,
                                maxLength: 14,
                                prefixIcon: Icons.phone_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                                    return 'Telefon numarası gereklidir';
                          }
                                  if (value.replaceAll(RegExp(r'[^\d]'), '').length != 10) {
                            return 'Geçerli bir telefon numarası giriniz';
                          }
                          return null;
                        },
                              ),
                      ),
                      const SizedBox(height: 16),
                            _buildAnimatedFormField(
                              DatePickerField(
                                controller: _birthDateController,
                                label: 'Doğum Tarihi',
                                onDateSelected: (date) {
                                  setState(() {});
                                },
                        ),
                      ),
                      const SizedBox(height: 16),
                            _buildAnimatedFormField(
                              GenderSelector(
                                onGenderSelected: (gender) {
                                  setState(() => _selectedGender = gender);
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Zaten hesabın var mı? ',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/login'),
                                  child: Text(
                                    'Giriş Yap',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                              ],
                            ),
                          ] else if (_currentStep == 1) ...[
                            _buildAnimatedFormField(
                              CustomTextField(
                                controller: _emailController,
                                label: 'E-posta',
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.validateEmail,
                                prefixIcon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildAnimatedFormField(
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Şifre',
                                isPassword: true,
                                validator: Validators.validatePassword,
                                prefixIcon: Icons.lock_outline,
                            ),
                          ),
                            const SizedBox(height: 16),
                            _buildAnimatedFormField(
                              CustomTextField(
                                controller: _confirmPasswordController,
                                label: 'Şifre Tekrar',
                                isPassword: true,
                        validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Şifreler eşleşmiyor';
                          }
                          return null;
                        },
                                prefixIcon: Icons.lock_outline,
                              ),
                            ),
                          ] else if (_currentStep == 2) ...[
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                        children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      size: 48,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Hesabınızı Oluşturmaya Hazırsınız!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Lütfen bilgilerinizi kontrol edin',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textSecondary,
                                ),
                      ),
                                  const SizedBox(height: 32),
                                  _buildAnimatedReviewItem(
                                    'Kullanıcı Adı',
                                    _usernameController.text,
                                    Icons.person_outline,
                                  ),
                                  _buildAnimatedReviewItem(
                                    'Telefon',
                                    _phoneController.text,
                                    Icons.phone_outlined,
                                  ),
                                  _buildAnimatedReviewItem(
                                    'E-posta',
                                    _emailController.text,
                                    Icons.email_outlined,
                                  ),
                                  _buildAnimatedReviewItem(
                                    'Doğum Tarihi',
                                    _birthDateController.text,
                                    Icons.cake_outlined,
                                  ),
                                  _buildAnimatedReviewItem(
                                    'Cinsiyet',
                                    _selectedGender,
                                    Icons.people_outline,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: CustomButton(
                          text: 'Geri',
                          onPressed: _previousStep,
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: _currentStep == _totalSteps - 1 ? 'Kayıt Ol' : 'İleri',
                        onPressed: _validateCurrentStep() ? _nextStep : null,
                        isLoading: _isLoading,
                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildAnimatedFormField(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildAnimatedReviewItem(String label, String value, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.divider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 