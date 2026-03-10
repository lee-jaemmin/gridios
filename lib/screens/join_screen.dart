import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';
import 'package:prost/widgets/join_table_gridview.dart'; // [필수] 분리한 위젯 임포트

class JoinScreen extends StatefulWidget {
  final String companyId;

  const JoinScreen({
    super.key,
    required this.companyId,
  });

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TableRepository _repo = TableRepository();

  // 선택 상태 관리
  String? _selectedMasterId;
  String? _selectedMasterName;
  final List<String> _selectedSlaveIds = [];
  final List<TableModel> _selectedSlaveTables = [];

  // 테이블 터치 핸들러 (합석 생성 + 해제 통합)
  void _onTableTap(TableModel table) {
    // 합석 해제
    if (table.groupid != null) {
      // 마스터 테이블 터치 -> 그룹 전체 해제 팝업
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('합석 해제'),
          content: Text(
            '${table.tablename} 테이블과 연결된\n모든 합석을 해제하시겠습니까?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await _repo.unjoinGroup(
                  company: widget.companyId,
                  groupid: table.groupid!,
                );
                if (mounted) Navigator.pop(context); // 다이얼로그 닫기
              },
              child: const Text('해제 확정', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return;
    }

    /// 신규 합석
    setState(() {
      // 마스터 선택
      if (_selectedMasterId == null) {
        if (table.status == 'available') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('빈 테이블은 기준 테이블로 선택할 수 없습니다.\n손님이 있는 테이블을 선택해주세요.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.black,
            ),
          );
          return;
        }

        _selectedMasterId = table.tid;
        _selectedMasterName = table.tablename;
      } else if (_selectedMasterId == table.tid) {
        _selectedMasterId = null;
        _selectedMasterName = null;
        _selectedSlaveIds.clear();
        _selectedSlaveTables.clear();
      }
      // 슬레이브 선택
      else {
        // 이미 선택된 슬레이브: 해제
        if (_selectedSlaveIds.contains(table.tid)) {
          _selectedSlaveIds.remove(table.tid);
          _selectedSlaveTables.removeWhere((t) => t.tid == table.tid);
        }
        // 새로운 슬레이브 선택
        else {
          if (table.status != 'available') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('사용 중인 테이블은 피합석 테이블로 선택할 수 없습니다.'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.black,
              ),
            );
            return;
          }
          _selectedSlaveIds.add(table.tid);
          _selectedSlaveTables.add(table);
        }
      }
    });
  }

  // 합석 확정
  Future<void> _executeJoin() async {
    if (_selectedMasterId == null || _selectedSlaveIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기준 테이블과 최소 1개 이상의 피합석 테이블을 선택해주세요.')),
      );
      return;
    }

    try {
      final checkSnapshot = await FirebaseFirestore.instance
          .collection('company')
          .doc(widget.companyId)
          .collection('tables')
          .where(FieldPath.documentId, whereIn: _selectedSlaveIds)
          .get();

      bool hasConflict = false;
      for (var doc in checkSnapshot.docs) {
        if (doc.data()['status'] != 'available') {
          hasConflict = true;
          break;
        }
      }

      if (hasConflict) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('요청 실패'),
            content: const Text('다른 직원이 이미 해당 테이블에 작업을 수행했습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
        return;
      }

      final masterDoc = await FirebaseFirestore.instance
          .collection('company')
          .doc(widget.companyId)
          .collection('tables')
          .doc(_selectedMasterId)
          .get();

      final masterTable = TableModel.fromMap(masterDoc.id, masterDoc.data()!);

      await _repo.joinGroup(
        company: widget.companyId,
        master: masterTable,
        slaves: _selectedSlaveTables,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Join Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

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
          .doc(widget.companyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final companyData = snapshot.data?.data() as Map<String, dynamic>?;
        final List<String> sections = List<String>.from(
          companyData?['sections'] ?? [],
        );
        sections.sort((a, b) => naturalSortCompare(a, b));

        return DefaultTabController(
          length: sections.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('합석 모드'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _executeJoin,
                    child: const Text('합석 완료'),
                  ),
                ),
              ],
              bottom: TabBar(
                indicatorWeight: 4,
                labelStyle: TextStyle(fontSize: 16),
                labelPadding: EdgeInsets.symmetric(horizontal: 20.0),
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: sections.map((s) => Tab(text: s)).toList(),
              ),
            ),
            body: Column(
              children: [
                // [상단 범례]
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(Colors.redAccent, '기준 테이블'),
                      const SizedBox(width: 15),
                      _buildLegend(Colors.green, '피합석 테이블'),
                      const SizedBox(width: 15),
                      _buildLegend(Colors.orangeAccent, '기존 합석'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: sections.map((section) {
                      return JoinTableGridView(
                        companyId: widget.companyId,
                        section: section,
                        selectedMasterId: _selectedMasterId,
                        selectedSlaveIds: _selectedSlaveIds,
                        onTableTap: _onTableTap, // 로직 전달
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
