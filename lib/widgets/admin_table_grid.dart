import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';
import 'package:prost/widgets/admin_add_table_card.dart';
import 'package:prost/widgets/admin_table_card.dart';

class AdminTableGrid extends StatelessWidget {
  final String companyid;
  final String section;
  final TableRepository _repo = TableRepository();

  AdminTableGrid({
    super.key,
    required this.companyid,
    required this.section,
  });

  // 테이블 추가 팝업
  void _showAddTableDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테이블 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '테이블 번호/이름 (예: A1)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('company')
                    .doc(companyid)
                    .collection('tables')
                    .add({
                      'tablename': controller.text.trim(),
                      'section': section,
                      'status': 'available',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TableModel>>(
      // 해당 섹션에 속한 테이블만 필터링해서 가져옴
      stream: _repo.getTablesStream(companyid, section),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final tables = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: tables.length + 1, // 테이블들 + 추가 버튼 카드
          itemBuilder: (context, index) {
            if (index == tables.length) {
              return AdminAddTableCard(
                onTapFunc: () => _showAddTableDialog(context),
              );
            }
            final tableDoc = tables[index];
            return AdminTableCard(
              table: tableDoc,
              companyId: companyid,
            );
          },
        );
      },
    );
  }
}
