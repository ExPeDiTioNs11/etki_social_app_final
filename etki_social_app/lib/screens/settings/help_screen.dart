import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Hesabımı nasıl güvenli hale getirebilirim?',
      'answer':
          'Hesabınızı güvenli hale getirmek için iki faktörlü doğrulamayı etkinleştirebilir, güçlü bir şifre kullanabilir ve düzenli olarak şifrenizi değiştirebilirsiniz.',
    },
    {
      'question': 'Profil fotoğrafımı nasıl değiştirebilirim?',
      'answer':
          'Profil fotoğrafınızı değiştirmek için profil sayfanıza gidin, profil fotoğrafınıza tıklayın ve "Düzenle" seçeneğini seçin.',
    },
    {
      'question': 'Gönderilerimi nasıl düzenleyebilirim?',
      'answer':
          'Gönderilerinizi düzenlemek için gönderiye tıklayın ve "Düzenle" seçeneğini seçin. Metin, fotoğraf ve diğer içerikleri değiştirebilirsiniz.',
    },
    {
      'question': 'Bildirimleri nasıl yönetebilirim?',
      'answer':
          'Bildirimleri yönetmek için ayarlar sayfasına gidin ve "Bildirimler" bölümünü seçin. Burada hangi bildirimleri almak istediğinizi seçebilirsiniz.',
    },
    {
      'question': 'Hesabımı nasıl silebilirim?',
      'answer':
          'Hesabınızı silmek için ayarlar sayfasına gidin, "Hesap" bölümünü seçin ve "Hesabı Sil" seçeneğini bulun.',
    },
  ];

  final List<bool> _isExpanded = List.generate(5, (index) => false);

  final List<Map<String, dynamic>> _supportOptions = [
    {
      'icon': Icons.email_outlined,
      'title': 'E-posta Desteği',
      'subtitle': 'support@etki.com',
    },
    {
      'icon': Icons.phone_outlined,
      'title': 'Telefon Desteği',
      'subtitle': '+90 555 123 4567',
    },
    {
      'icon': Icons.chat_outlined,
      'title': 'Canlı Destek',
      'subtitle': '7/24 Canlı Destek',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Yardım'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sık Sorulan Sorular
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sık Sorulan Sorular',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_faqs.length, (index) {
                    final faq = _faqs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isExpanded[index] = !_isExpanded[index];
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: _isExpanded[index]
                                  ? AppColors.primary.withOpacity(0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isExpanded[index]
                                    ? AppColors.primary.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          faq['question'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      AnimatedRotation(
                                        duration: const Duration(milliseconds: 300),
                                        turns: _isExpanded[index] ? 0.5 : 0,
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: _isExpanded[index]
                                              ? AppColors.primary
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isExpanded[index])
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Text(
                                      faq['answer'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Destek Seçenekleri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Destek Seçenekleri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._supportOptions.map((option) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // TODO: Implement support option action
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  option['icon'],
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option['subtitle'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Yardım Merkezi
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Implement help center navigation
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.help_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yardım Merkezi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Detaylı yardım ve kılavuzlar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 