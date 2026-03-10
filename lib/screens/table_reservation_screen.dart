import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prost/class/app_user.dart';
import 'package:prost/class/table_repo.dart';
import 'package:prost/class/table.dart';
import 'package:prost/widgets/reservation_gridview.dart';

class TableReservationScreen extends StatefulWidget {
  const TableReservationScreen({super.key});

  @override
  State<TableReservationScreen> createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen> {
  final TableRepository _repo = TableRepository();

  // 현재 유저 정보 가져오기 (HomeScreen과 동일 로직)
  Future<AppUser> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return AppUser.fromMap(doc.id, doc.data()!);
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

  Future<void> _selectReservationTime(
    BuildContext context,
    String companyId,
    TableModel table,
  ) async {
    // 초기값 설정 (현재 시간 기준 5분 단위 반올림)
    DateTime now = DateTime.now();
    int initialMinute = (now.minute / 5).round() * 5;
    DateTime initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      initialMinute,
    );

    // 임시로 선택된 시간을 담을 변수
    DateTime selectedDateTime = initialDateTime;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // 상단 바 (취소/완료 버튼)
            Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('취소'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('완료'),
                    onPressed: () async {
                      // 완료 클릭 시 DB 업데이트 로직 실행
                      final String formattedTime =
                          "${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}";

                      await _repo.updateReservation(
                        companyId,
                        table.tid,
                        formattedTime,
                      ); //
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // 쿠퍼티노 타임 피커 본체
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: initialDateTime,
                minuteInterval: 5, // [핵심] 5분 단위 강제 설정
                onDateTimeChanged: (DateTime newDateTime) {
                  selectedDateTime = newDateTime;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
      future: _fetchCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        final currentUser = snapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('company')
              .doc(currentUser.companyid)
              .snapshots(),
          builder: (context, companySnapshot) {
            if (!companySnapshot.hasData)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );

            final companyData =
                companySnapshot.data?.data() as Map<String, dynamic>?;
            final List<String> sections = List<String>.from(
              companyData?['sections'] ?? [],
            );
            sections.sort((a, b) => naturalSortCompare(a, b));

            return DefaultTabController(
              length: sections.length,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('예약 관리'),
                  bottom: sections.isEmpty
                      ? null
                      : TabBar(
                          indicatorWeight: 4,
                          labelStyle: TextStyle(fontSize: 16),
                          labelPadding: EdgeInsets.symmetric(horizontal: 20.0),
                          tabAlignment: TabAlignment.start,
                          isScrollable: true,
                          tabs: sections.map((s) => Tab(text: s)).toList(),
                        ),
                ),
                body: TabBarView(
                  children: sections.map((section) {
                    // 예약 화면용 GridView 커스텀 (onTap 오버라이드를 위해 모델 활용)
                    return ReservationGridView(
                      companyId: currentUser.companyid,
                      section: section,
                      onTableTap: (table) => _selectReservationTime(
                        context,
                        currentUser.companyid,
                        table,
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
