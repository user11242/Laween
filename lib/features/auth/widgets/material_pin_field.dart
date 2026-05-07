import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MaterialPinField extends StatefulWidget {
  final int length;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final Function(String)? onCompleted;
  final bool isLight;

  const MaterialPinField({
    super.key,
    required this.length,
    required this.controller,
    this.onChanged,
    this.onCompleted,
    this.isLight = false,
  });

  @override
  State<MaterialPinField> createState() => _MaterialPinFieldState();
}

class _MaterialPinFieldState extends State<MaterialPinField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    
    // Sync with main controller if needed, but we'll use these internally
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() {
        _updateMainController();
      });
    }
  }

  void _updateMainController() {
    String value = _controllers.map((c) => c.text).join();
    widget.controller.text = value;
    if (widget.onChanged != null) widget.onChanged!(value);
    if (value.length == widget.length && widget.onCompleted != null) {
      widget.onCompleted!(value);
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controllers[index].text.isEmpty &&
                  index > 0) {
                _controllers[index - 1].clear();
                _focusNodes[index - 1].requestFocus();
              }
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                color: widget.isLight ? Colors.black : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: "",
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isLight 
                      ? Colors.black.withOpacity(0.1) 
                      : Colors.white.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF006D77), width: 2),
                ),
                fillColor: widget.isLight 
                  ? Colors.grey.withOpacity(0.05) 
                  : Colors.white.withOpacity(0.05),
                filled: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
              ],
              onChanged: (value) {
                // Convert Arabic digits to English
                const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
                const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
                String convertedValue = value;
                for (int i = 0; i < 10; i++) {
                  convertedValue = convertedValue.replaceAll(arabicDigits[i], englishDigits[i]);
                }

                if (convertedValue != value) {
                  _controllers[index].text = convertedValue;
                  _controllers[index].selection = TextSelection.fromPosition(
                    TextPosition(offset: convertedValue.length),
                  );
                }

                if (convertedValue.isNotEmpty) {
                  if (index < widget.length - 1) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                  }
                } else {
                  if (index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                }
              },
            ),
          ),
        );
      }),
    );
  }
}
