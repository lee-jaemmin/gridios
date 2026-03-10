import 'package:flutter/material.dart';

class SidebarMenu extends StatelessWidget {
  final String name;
  final VoidCallback onTapFunc; // 클릭했을 때 실행할 함수를 받음

  const SidebarMenu({
    super.key,
    required this.name,
    required this.onTapFunc,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ), // 아이콘 추가로 시인성 업!
        onTap: onTapFunc, // [핵심] 여기서 비로소 터치를 인식하고 함수를 실행합니다.
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
    );
  }
}
