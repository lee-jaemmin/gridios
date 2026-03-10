import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';

class MoveScreen extends StatelessWidget {
  final String companyId;
  final TableModel fromTable; // 어디에서 이동하는지 정보

  const MoveScreen({
    super.key,
    required this.companyId,
    required this.fromTable,
  });

  int naturalSortCompare(String a, String b) {
    // 숫자와 숫자가 아닌 부분을 분리하는 정규식
    final regExp = RegExp(r'([0-9]+)|([^0-9]+)');
    final matchesA = regExp.allMatches(a).toList();
    final matchesB = regExp.allMatches(b).toList();

    for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
      final groupA = matchesA[i].group(0)!;
      final groupB = matchesB[i].group(0)!;

      // 두 부분이 모두 숫자인 경우 숫자로 비교
      if (RegExp(r'^[0-9]+$').hasMatch(groupA) &&
          RegExp(r'^[0-9]+$').hasMatch(groupB)) {
        int numA = int.parse(groupA);
        int numB = int.parse(groupB);
        if (numA != numB) return numA.compareTo(numB);
      } else {
        // 숫자가 아닌 경우 문자열로 비교
        int res = groupA.compareTo(groupB);
        if (res != 0) return res;
      }
    }
    return a.length.compareTo(b.length);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('company')
          .doc(companyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        final companyData = snapshot.data?.data() as Map<String, dynamic>?;
        final List<String> sections = List<String>.from(
          companyData?['sections'] ?? [],
        );
        sections.sort((a, b) => naturalSortCompare(a, b));

        return DefaultTabController(
          length: sections.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text('${fromTable.tablename} 이동 위치 선택'),
              bottom: TabBar(
                indicatorWeight: 4,
                labelStyle: TextStyle(fontSize: 16),
                labelPadding: EdgeInsets.symmetric(horizontal: 20.0),
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: sections.map((s) => Tab(text: s)).toList(),
              ),
            ),
            body: TabBarView(
              children: sections
                  .map(
                    (section) => MoveTableGridView(
                      companyId: companyId,
                      section: section,
                      fromTable: fromTable,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class MoveTableGridView extends StatelessWidget {
  final String companyId;
  final String section;
  final TableModel fromTable;
  final TableRepository _repo = TableRepository();

  MoveTableGridView({
    required this.companyId,
    required this.section,
    required this.fromTable,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TableModel>>(
      stream: _repo.getTablesStream(companyId, section),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final tables = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final targetTable = tables[index];
            bool isAvailable = targetTable.status == 'available';

            return GestureDetector(
              onTap: isAvailable
                  ? () => _confirmMove(context, targetTable)
                  : null,
              child: Card(
                // 사용 중이면 회색, 이동 가능하면 파란색
                color: isAvailable ? Colors.blue[100] : Colors.grey[300],
                child: Center(
                  child: Text(
                    targetTable.tablename,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmMove(BuildContext context, TableModel targetTable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테이블 이동'),
        content: Text(
          '${fromTable.tablename}의 정보를 ${targetTable.tablename}으로 이동하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _repo.moveTable(companyId, fromTable, targetTable.tid);

                if (context.mounted) {
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // 이동 화면 닫기
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // 다이얼로그 닫기

                  // 에러 메시지에 따른 스낵바 노출
                  String errorMsg = e.toString().contains("ALREADY_IN_USE")
                      ? "이미 다른 직원이 해당 테이블을 사용 중입니다."
                      : "이동 중 오류가 발생했습니다.";

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('이동 확정'),
          ),
        ],
      ),
    );
  }
}
