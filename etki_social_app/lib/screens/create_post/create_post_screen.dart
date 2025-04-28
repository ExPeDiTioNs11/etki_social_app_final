import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:etki_social_app/constants/app_colors.dart';
import 'package:etki_social_app/widgets/custom_button.dart';
import 'package:etki_social_app/widgets/custom_text_field.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:etki_social_app/services/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController = TextEditingController();
  final TextEditingController _taskCoinController = TextEditingController();
  final TextEditingController _taskParticipantController = TextEditingController();
  final TextEditingController _taskDurationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  List<File> _selectedImages = [];
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  int _selectedDuration = 1;
  String _selectedDurationType = 'gün';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _taskDurationController.text = _selectedDuration.toString();
    _taskDurationController.addListener(_updateDuration);
  }

  void _updateDuration() {
    setState(() {
      _selectedDuration = int.tryParse(_taskDurationController.text) ?? 1;
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('Kullanıcı girişi yapılmamış');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (mounted && userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          print('Kullanıcı verileri yüklendi: $userData');
          setState(() {
            _userData = {
              'username': userData['username'] ?? 'Kullanıcı',
              'profileImageUrl': userData['profileImageUrl'] ?? userData['profileImage'] ?? '',
            };
          });
        } else {
          print('Kullanıcı verileri boş');
        }
      } else {
        print('Kullanıcı dokümanı bulunamadı');
      }
    } catch (e) {
      print('Kullanıcı verileri yüklenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bilgileri yüklenirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _taskCoinController.dispose();
    _taskParticipantController.dispose();
    _taskDurationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildCoinIcon({double size = 16}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.amber,
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '₺',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            const Text(
              'Yeni Görev Oluştur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Görevinizi detaylı bir şekilde açıklayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Görev Başlığı
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: CustomTextField(
                controller: _taskTitleController,
                label: 'Görev Başlığı',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen görev başlığı girin';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Görev Açıklaması
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: CustomTextField(
                controller: _taskDescriptionController,
                label: 'Görev Açıklaması',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen görev açıklaması girin';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Ödül ve Katılımcı Bilgileri
            Row(
              children: [
                // Coin Miktarı
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: CustomTextField(
                      controller: _taskCoinController,
                      label: 'Ödül Coin',
                      keyboardType: TextInputType.number,
                      prefixIcon: null,
                      prefix: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCoinIcon(size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen coin miktarı girin';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Geçerli bir sayı girin';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Katılımcı Sayısı
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: CustomTextField(
                      controller: _taskParticipantController,
                      label: 'Katılımcı Sayısı',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.people,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen katılımcı sayısı girin';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Geçerli bir sayı girin';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Süre Seçimi
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görev Süresi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _taskDurationController,
                          label: 'Süre',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.timer,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen süre girin';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Geçerli bir sayı girin';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedDurationType,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'gün', child: Text('Gün')),
                            DropdownMenuItem(value: 'saat', child: Text('Saat')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDurationType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Paylaş Butonu
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Görevi Paylaş',
                isLoading: _isLoading,
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _handleTaskSubmit();
                  }
                },
                backgroundColor: Colors.transparent,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePostSubmit() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Kullanıcı girişi yapılmamış');

      // Kullanıcı verilerini kontrol et ve yükle
      if (_userData == null) {
        await _loadUserData();
      }

      if (_userData == null) {
        throw Exception('Kullanıcı verileri yüklenemedi');
      }

      final username = _userData!['username']?.toString() ?? 'Kullanıcı';
      final profileImage = _userData!['profileImageUrl']?.toString() ?? '';

      // Resimleri yükle
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        for (var image in _selectedImages) {
          final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
          final ref = FirebaseStorage.instance.ref().child('post_images').child(fileName);
          
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': user.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          );

          final uploadTask = ref.putFile(image, metadata);
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        }
      }

      // Gönderi verisi
      final post = {
        'content': _postController.text,
        'userId': user.uid,
        'username': username,
        'profileImage': profileImage,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': [],
        'shares': 0,
        'type': _selectedImages.isNotEmpty ? 'image' : 'text',
        'imageUrls': imageUrls,
      };

      // Gönderiyi posts koleksiyonuna ekle
      await FirebaseFirestore.instance.collection('posts').add(post);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderi başarıyla paylaşıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Gönderi paylaşılırken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gönderi paylaşılırken bir hata oluştu: $e'),
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

  Future<void> _handleTaskSubmit() async {
    if (_formKey.currentState == null) {
      print('Form state is null');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('Kullanıcı girişi yapılmamış');
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      // Kullanıcı verilerini kontrol et ve yükle
      if (_userData == null) {
        await _loadUserData();
      }

      if (_userData == null) {
        print('Kullanıcı verileri yüklenemedi');
        throw Exception('Kullanıcı verileri yüklenemedi');
      }

      final username = _userData!['username']?.toString() ?? 'Kullanıcı';
      final profileImage = _userData!['profileImageUrl']?.toString() ?? '';

      // Görev verisi
      final task = {
        'title': _taskTitleController.text,
        'description': _taskDescriptionController.text,
        'coinAmount': int.parse(_taskCoinController.text),
        'participantCount': int.parse(_taskParticipantController.text),
        'duration': _selectedDuration,
        'durationType': _selectedDurationType,
        'deadline': DateTime.now().add(
          Duration(
            days: _selectedDurationType == 'gün' ? _selectedDuration : 0,
            hours: _selectedDurationType == 'saat' ? _selectedDuration : 0,
          ),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'participants': [],
        'creatorId': user.uid,
        'creatorUsername': username,
        'creatorProfileImage': profileImage,
        'likes': [],
        'comments': [],
        'shares': 0,
        'type': 'mission',
      };

      // Görevi sadece tasks koleksiyonuna ekle
      await FirebaseFirestore.instance.collection('tasks').add(task);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev başarıyla paylaşıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Görev paylaşılırken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev paylaşılırken bir hata oluştu: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Modal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Çizgi
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // TabBar
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Paylaşım'),
                    Tab(text: 'Görev'),
                  ],
                ),
              ],
            ),
          ),
          // Modal Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Paylaşım Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil ve İsim
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            backgroundImage: _userData?['profileImageUrl'] != null
                                ? NetworkImage(_userData!['profileImageUrl'])
                                : null,
                            child: _userData?['profileImageUrl'] == null
                                ? Text(
                                    _userData?['username']?.toString().substring(0, 1).toUpperCase() ?? '?',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData?['username'] ?? 'Kullanıcı',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Şimdi',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Gönderi İçeriği
                      TextField(
                        controller: _postController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Ne düşünüyorsun?',
                          border: InputBorder.none,
                        ),
                      ),
                      
                      // Seçilen Resimler
                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: FileImage(_selectedImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Resim Ekleme Butonu
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Galeriden Seç',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Paylaş Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handlePostSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Paylaş',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Görev Tab
                _buildTaskTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 