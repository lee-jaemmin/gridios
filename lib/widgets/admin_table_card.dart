import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';

/// 관리자용 추가, 삭제 가능한 테이블 UI
class AdminTableCard extends StatelessWidget {
  final TableModel table;
  final String companyId;
  final TableRepository _repo = TableRepository();

  AdminTableCard({
    super.key,
    required this.table,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            table.tablename, // 테이블 이름 (예: A1)
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Positioned(
          // 마이너스 기호
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () async =>
                await _repo.deleteTable(companyId, table.tid), // 테이블 즉시 삭제
            child: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
          ),
        ),
      ],
    );
  }
}
