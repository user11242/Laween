import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

// This widget now uses the pin_code_fields plugin but keeps your custom style
class OtpInputWidget extends StatelessWidget {
  final PinInputController controller; // Plugin uses one controller, not a list
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
            width: 330, // Matching your container width
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MaterialPinField(
                length: 6,
                pinController: controller,
                keyboardType: TextInputType.number,
                
                // Styling to match your BoxDecoration
                theme: MaterialPinTheme(
                  shape: MaterialPinShape.outlined,
                  borderRadius: BorderRadius.circular(10),
                  cellSize: const Size(45, 55),
                  
                  // Colors matching: Colors.black.withValues(alpha: 0.25)
                  fillColor: Colors.black.withValues(alpha: 0.25),
                  focusedFillColor: Colors.black.withValues(alpha: 0.25),
                  filledFillColor: Colors.black.withValues(alpha: 0.4),
                  
                  // Borders (Set to transparent to let the shadow/box define the look)
                  borderColor: Colors.transparent,
                  focusedBorderColor: Colors.transparent,
                  filledBorderColor: Colors.white.withValues(alpha: 0.5),
                  
                  textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                  
                  // Applying your specific BoxShadow
                  boxShadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                onChanged: onChanged,
                onCompleted: onCompleted,
              ),
            ),
          ),

          // Show error text below if provided
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
