import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AgreeCheckbox extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTapTitle;

  AgreeCheckbox({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onTapTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onTapTitle,
                ),
                const TextSpan(text: "에 동의합니다 (필수)"),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
