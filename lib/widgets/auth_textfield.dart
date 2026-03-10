import 'package:flutter/material.dart';

class AuthTextfield extends StatelessWidget {
  // 함수에서 인자로 받던 것들을 클래스 멤버 변수로 선언합니다.
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  // 생성자를 통해 값을 전달받습니다.
  const AuthTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false, // 기본값 설정
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.black),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '내용을 입력해주세요.';
          }
          return null;
        },
      ),
    );
  }
}
