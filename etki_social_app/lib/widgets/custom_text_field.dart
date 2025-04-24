import 'package:flutter/material.dart';
import 'package:etki_social_app/utils/theme.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPhoneNumber;
  final int? maxLength;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.isPassword = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.isPhoneNumber = false,
    this.maxLength,
  });

  String _formatPhoneNumber(String value) {
    // Sadece rakamları al
    String digits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format the phone number
    if (digits.isEmpty) return '';
    if (digits.length <= 3) {
      return digits;
    } else if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    } else if (digits.length <= 8) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPhoneNumber ? TextInputType.phone : keyboardType,
      validator: validator,
      maxLength: isPhoneNumber ? 14 : maxLength, // 5XX XXX XX XX = 14 karakter (boşluklar dahil)
      inputFormatters: isPhoneNumber
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10), // 10 rakam
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                return TextEditingValue(
                  text: _formatPhoneNumber(newValue.text),
                  selection: TextSelection.collapsed(
                    offset: _formatPhoneNumber(newValue.text).length,
                  ),
                );
              }),
            ]
          : null,
      style: TextStyle(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: AppTheme.primaryColor,
              )
            : null,
        prefix: isPhoneNumber
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '+90',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : null,
        suffixIcon: suffixIcon,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
} 