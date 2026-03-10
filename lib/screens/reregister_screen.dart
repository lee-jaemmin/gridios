import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';

class ReregisterScreen extends StatelessWidget {
  final String companyId;
  final Map<String, dynamic> historyData; // 히스토리에서 넘어온 데이터

  const ReregisterScreen({
    super.key,
    required this.companyId,
    required this.historyData,
  });

  // 섹션 정렬을 위한 내츄럴 솔트 함수
  int naturalSortCompare(String a, String b) {
    final regExp = RegExp(r'([0-9]+)|([^0-9]+)');
    final matchesA = regExp.allMatches(a).toList();
    final matchesB = regExp.allMatches(b).toList();

    for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
      final groupA = matchesA[i].group(0)!;
      final groupB = matchesB[i].group(0)!;

      if (RegExp(r'^[0-9]+$').hasMatch(groupA) &&
          RegExp(r'^[0-9]+$').hasMatch(groupB)) {
        int numA = int.parse(groupA);
        int numB = int.parse(groupB);
        if (numA != numB) return numA.compareTo(numB);
      } else {
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
              title: const Text('재등록 위치 선택'),
              bottom: TabBar(
                indicatorWeight: 4,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: sections.map((s) => Tab(text: s)).toList(),
              ),
            ),
            body: TabBarView(
              children: sections
                  .map(
                    (section) => ReregisterTableGridView(
                      companyId: companyId,
                      section: section,
                      historyData: historyData,
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

class ReregisterTableGridView extends StatelessWidget {
  final String companyId;
  final String section;
  final Map<String, dynamic> historyData;
  final TableRepository _repo = TableRepository();

  ReregisterTableGridView({
    super.key,
    required this.companyId,
    required this.section,
    required this.historyData,
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
            // [조건] 빈 테이블(available)만 선택 가능하게 설정
            bool isAvailable = targetTable.status == 'available';

            return GestureDetector(
              onTap: isAvailable
                  ? () => _confirmReregister(context, targetTable)
                  : null,
              child: Card(
                color: isAvailable ? Colors.green[50] : Colors.grey[300],
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

  void _confirmReregister(BuildContext context, TableModel targetTable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정보 재등록'),
        content: Text(
          '${historyData['customer']}님의 정보를\n${targetTable.tablename}번 테이블로 재등록하시겠습니까?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // [핵심] 기존 정보를 새 테이블에 등록
                await _repo.registerBottleKeep(
                  company: companyId,
                  tid: targetTable.tid,
                  customer: historyData['customer'] ?? '',
                  phonenumber: historyData['phonenumber'] ?? '',
                  staff: historyData['staff'] ?? '',
                  persons: historyData['persons'] ?? 0,
                  bottle: historyData['bottle'] ?? '',
                  remark: '${historyData['remark'] ?? ''} (재등록)', // 재등록 흔적 남김
                );

                if (context.mounted) {
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // ReregisterScreen 닫기
                  Navigator.pop(context); // HistoryBottomSheet 닫기
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('재등록 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('확정'),
          ),
        ],
      ),
    );
  }
}
