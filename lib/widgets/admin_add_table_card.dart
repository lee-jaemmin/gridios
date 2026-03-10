import 'package:flutter/material.dart';

/// 테이블 추가 전용 테이블

class AdminAddTableCard extends StatelessWidget {
  final VoidCallback onTapFunc;
  const AdminAddTableCard({super.key, required this.onTapFunc});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapFunc,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, size: 30, color: Colors.grey),
      ),
    );
  }
}
