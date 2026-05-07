import 'package:flutter/material.dart';
import '../material_pin_field.dart';

class OtpInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String)? onChanged;
  final Function(String)? onCompleted;

  const OtpInputWidget({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            width: 330,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MaterialPinField(
                length: 6,
                controller: controller,
                isLight: true, // Assuming light for this specific widget usage
                onChanged: onChanged,
                onCompleted: onCompleted,
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
