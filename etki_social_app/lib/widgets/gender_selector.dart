import 'package:flutter/material.dart';
import 'package:etki_social_app/utils/theme.dart';

class GenderSelector extends StatelessWidget {
  final Function(String) onGenderSelected;

  const GenderSelector({
    super.key,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cinsiyet',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                'Erkek',
                Icons.male,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderOption(
                'Kadın',
                Icons.female,
                AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderOption(
                'Diğer',
                Icons.transgender,
                AppTheme.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () => onGenderSelected(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.divider,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 