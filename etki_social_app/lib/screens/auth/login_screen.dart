import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _authService = AuthService();
  List<String> _savedEmails = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    _loadSavedEmails();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmails() async {
    final emails = await _authService.getSavedEmails();
    final lastUsedEmail = await _authService.getLastUsedEmail();
    
    setState(() {
      _savedEmails = emails;
      if (lastUsedEmail != null) {
        _emailController.text = lastUsedEmail;
        _loadPasswordForEmail(lastUsedEmail);
      }
    });
  }

  Future<void> _loadPasswordForEmail(String email) async {
    final password = await _authService.getSavedPassword(email);
    if (password != null) {
      setState(() {
        _passwordController.text = password;
      });
    }
  }

  void _showEmailOptions() {
    if (_savedEmails.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Kayıtlı E-postalar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              _savedEmails.length,
              (index) => ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(_savedEmails[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await _authService.removeSavedEmail(_savedEmails[index]);
                    await _loadSavedEmails();
                    if (_emailController.text == _savedEmails[index]) {
                      setState(() {
                        _passwordController.text = '';
                      });
                    }
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  _emailController.text = _savedEmails[index];
                  _loadPasswordForEmail(_savedEmails[index]);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().contains('user-not-found')
                    ? 'Kullanıcı bulunamadı'
                    : e.toString().contains('wrong-password')
                        ? 'Yanlış şifre'
                        : e.toString().contains('invalid-email')
                            ? 'Geçersiz e-posta adresi'
                            : 'Giriş yapılırken bir hata oluştu',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Logo or Animation
                Lottie.asset(
                  'assets/animations/social_media.json',
                  height: 200,
                  repeat: true,
                ),
                const SizedBox(height: 32),
                Text(
                  'Hoş Geldiniz!',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sosyal dünyaya bağlanmak için giriş yapın',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: const Icon(Icons.email_outlined),
                          suffixIcon: _savedEmails.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onPressed: _showEmailOptions,
                                )
                              : null,
                        ),
                        onTap: () {
                          if (_savedEmails.isNotEmpty) {
                            _showEmailOptions();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-posta adresi gerekli';
                          }
                          if (!value.contains('@')) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Şifre zorunludur'),
                          MinLengthValidator(6,
                              errorText: 'Şifre en az 6 karakter olmalıdır'),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
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
                            : const Text('Giriş Yap'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          context.go('/register');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                        ),
                        child: const Text('Hesabınız yok mu? Kayıt olun'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 