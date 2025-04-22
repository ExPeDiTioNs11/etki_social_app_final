import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:lottie/lottie.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTermsAccepted = false;
  DateTime? _birthDate;
  String? _selectedGender;

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
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // TODO: Implement register logic
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
      });
    }
  }

  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kullanıcı Sözleşmesi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: SingleChildScrollView(
                      child: Text(
                        '''
1. Gizlilik ve Veri Kullanımı
   - Kullanıcı verileriniz güvenli bir şekilde saklanacaktır
   - Verileriniz yalnızca hizmetlerimizi iyileştirmek için kullanılacaktır
   - Üçüncü taraflarla veri paylaşımı yapılmayacaktır
   - Veri işleme politikamız KVKK ve GDPR uyumludur
   - Verileriniz şifrelenerek saklanır
   - Düzenli güvenlik denetimleri yapılır
   - Veri sızıntısı durumunda size bilgi verilir

2. Hesap Güvenliği
   - Hesabınızın güvenliğinden siz sorumlusunuz
   - Şifrenizi güçlü tutmanız önerilir
   - Şüpheli aktiviteleri bildirmeniz gerekir
   - İki faktörlü doğrulama kullanmanız önerilir
   - Oturum açma bilgilerinizi kimseyle paylaşmayın
   - Düzenli şifre değişikliği yapmanız önerilir
   - Güvenlik bildirimlerini aktif tutun

3. İçerik Kuralları
   - Yasa dışı içerik paylaşımı yasaktır
   - Başkalarının haklarına saygı gösterilmelidir
   - Spam ve reklam içerikleri yasaktır
   - Nefret söylemi ve ayrımcılık yasaktır
   - Telif hakkı ihlali yasaktır
   - Yanıltıcı bilgi paylaşımı yasaktır
   - Uygunsuz içerik paylaşımı yasaktır

4. Hesap İptali
   - Hesabınızı istediğiniz zaman silebilirsiniz
   - Hesap silme işlemi geri alınamaz
   - Silinen veriler 30 gün içinde tamamen kaldırılır
   - Hesap silme talebi 24 saat içinde işleme alınır
   - Silinen verilerin yedekleri de temizlenir
   - Hesap silme sonrası geri dönüş yapılamaz
   - Silme işlemi tüm platformlarda geçerlidir

5. Hizmet Kullanımı
   - Hizmetlerimizi mevcut haliyle sunuyoruz
   - Kesintisiz hizmet garantisi vermiyoruz
   - Hizmet değişikliklerini önceden bildiriyoruz
   - Bakım çalışmaları için bilgilendirme yapıyoruz
   - Teknik sorunlar için destek sağlıyoruz
   - Hizmet kalitesini sürekli iyileştiriyoruz
   - Kullanıcı geri bildirimlerini değerlendiriyoruz

6. Sorumluluklar
   - Kullanıcılar kendi paylaşımlarından sorumludur
   - Platform içerikleri denetler ve kaldırabilir
   - Yasal zorunluluklar için işbirliği yapılır
   - Hizmet kesintilerinden sorumlu değiliz
   - Üçüncü taraf hizmetlerinden sorumlu değiliz
   - Kullanıcı hatalarından sorumlu değiliz
   - Doğal afetlerden kaynaklı kesintilerden sorumlu değiliz
                      ''',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Anladım'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  bool _isValidPhoneNumber(String phone) {
    // Türkiye telefon numarası formatı: 5XX XXX XX XX
    final RegExp phoneRegex = RegExp(r'^5[0-9]{2}\s[0-9]{3}\s[0-9]{2}\s[0-9]{2}$');
    return phoneRegex.hasMatch(phone);
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
                  'assets/animations/register.json',
                  height: 200,
                  repeat: true,
                ),
                const SizedBox(height: 32),
                Text(
                  'Hesap Oluştur',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sosyal dünyaya katılmak için kayıt olun',
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
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'Kullanıcı adı zorunludur'),
                          MinLengthValidator(3,
                              errorText:
                                  'Kullanıcı adı en az 3 karakter olmalıdır'),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(errorText: 'E-posta zorunludur'),
                          EmailValidator(errorText: 'Geçerli bir e-posta giriniz'),
                        ]),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Şifre Tekrar',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Şifreler eşleşmiyor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon Numarası',
                          prefixIcon: Icon(Icons.phone_outlined),
                          prefixText: '+90 ',
                          hintText: '5XX XXX XX XX',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Telefon numarası zorunludur';
                          }
                          if (!_isValidPhoneNumber(value)) {
                            return 'Geçerli bir telefon numarası giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _selectBirthDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined),
                              const SizedBox(width: 16),
                              Text(
                                _birthDate != null
                                    ? 'Doğum Tarihi: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                    : 'Doğum Tarihi Seçin',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Cinsiyet',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        dropdownColor: Colors.white,
                        style: Theme.of(context).textTheme.bodyMedium,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        borderRadius: BorderRadius.circular(12),
                        items: [
                          DropdownMenuItem(
                            value: 'male',
                            child: Row(
                              children: [
                                Icon(Icons.male, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('Erkek'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Row(
                              children: [
                                Icon(Icons.female, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('Kadın'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Row(
                              children: [
                                Icon(Icons.transgender, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('Diğer'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'prefer_not_to_say',
                            child: Row(
                              children: [
                                Icon(Icons.question_mark, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('Belirtmek İstemiyorum'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Cinsiyet seçimi zorunludur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _isTermsAccepted,
                            onChanged: (value) {
                              setState(() {
                                _isTermsAccepted = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsModal,
                              child: Text(
                                'Kullanıcı sözleşmesini okudum ve kabul ediyorum',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _isTermsAccepted ? AppColors.textPrimary : AppColors.textSecondary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _isTermsAccepted ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading || !_isTermsAccepted ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Kayıt Ol'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          context.go('/');
                        },
                        child: const Text('Zaten hesabınız var mı? Giriş yapın'),
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