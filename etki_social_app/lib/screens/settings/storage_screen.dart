import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  bool _autoClearCache = true;
  bool _saveToGallery = true;
  bool _useLessData = false;

  // Örnek depolama verileri
  final Map<String, double> _storageData = {
    'Önbellek': 125.5, // MB
    'Medya': 345.2, // MB
    'Uygulama': 85.7, // MB
  };

  String _formatSize(double size) {
    if (size < 1024) {
      return '${size.toStringAsFixed(1)} MB';
    } else {
      return '${(size / 1024).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Depolama'),
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
            // Depolama Kullanımı
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
                    'Depolama Kullanımı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._storageData.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            _formatSize(entry.value),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: 0.6, // Örnek değer
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Depolama Ayarları
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
                    'Depolama Ayarları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStorageSwitch(
                    title: 'Önbelleği Otomatik Temizle',
                    subtitle: 'Önbellek 100 MB\'ı geçtiğinde otomatik temizle',
                    value: _autoClearCache,
                    onChanged: (value) {
                      setState(() {
                        _autoClearCache = value;
                      });
                    },
                  ),
                  _buildStorageSwitch(
                    title: 'Galeriye Kaydet',
                    subtitle: 'Medya dosyalarını cihaz galerisine kaydet',
                    value: _saveToGallery,
                    onChanged: (value) {
                      setState(() {
                        _saveToGallery = value;
                      });
                    },
                  ),
                  _buildStorageSwitch(
                    title: 'Daha Az Veri Kullan',
                    subtitle: 'Düşük kaliteli medya indir',
                    value: _useLessData,
                    onChanged: (value) {
                      setState(() {
                        _useLessData = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Temizleme Butonları
            Row(
              children: [
                Expanded(
                  child: _buildClearButton(
                    icon: Icons.delete_outline,
                    title: 'Önbelleği Temizle',
                    onTap: () {
                      // TODO: Implement clear cache
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildClearButton(
                    icon: Icons.photo_library_outlined,
                    title: 'Medyayı Temizle',
                    onTap: () {
                      // TODO: Implement clear media
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 