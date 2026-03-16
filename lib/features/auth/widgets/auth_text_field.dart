import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final bool showToggle;
  final bool isObscured;
  final VoidCallback? onToggle;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;

  // 🔹 VALIDATION PROPS
  final Function(String)? onChanged;
  final String? errorText;
  final bool isSuccess; 
  final bool isLoading; 
  final VoidCallback? onPaste;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.showToggle = false,
    this.isObscured = false,
    this.onToggle,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.onChanged,
    this.errorText,
    this.isSuccess = false,
    this.isLoading = false,
    this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    // Determine Border Color
    Color borderColor = Colors.transparent;
    if (errorText != null) {
      borderColor = Colors.redAccent;
    } else if (isSuccess) {
      borderColor = Colors.greenAccent; // 🟢 Green if valid
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withAlpha(51),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure && (showToggle ? isObscured : true),
            style: const TextStyle(color: Colors.white),
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            maxLines: maxLines,
            minLines: minLines,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.white.withAlpha(128),
                fontSize: 15,
              ),
              hintMaxLines: 2,
              prefixIcon: Icon(icon, color: AppColors.textColor),

              // 🔹 Borders
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.redAccent
                        : (isSuccess ? Colors.greenAccent : AppColors.accentGold), // ✅ Gold Focus
                    width: 2,
                  ),
                ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onPaste != null)
                          IconButton(
                            icon: const Icon(Icons.content_paste, size: 20),
                            color: AppColors.textColor.withValues(alpha: 0.7),
                            onPressed: onPaste,
                            tooltip: AppLocalizations.of(context)!.paste,
                          ),
                        if (showToggle)
                          IconButton(
                            icon: Icon(
                              isObscured ? Icons.visibility_off : Icons.visibility,
                              color: isSuccess ? Colors.greenAccent : AppColors.textColor,
                            ),
                            onPressed: onToggle,
                          )
                        else if (isSuccess)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.check_circle, color: Colors.greenAccent),
                          ),
                      ],
                    ),
            ),
          ),
        ),

        // 🔹 Error Message
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6, bottom: 5),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        if (errorText == null) const SizedBox(height: 15),
      ],
    );
  }
}
