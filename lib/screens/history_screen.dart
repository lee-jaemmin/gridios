import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prost/widgets/history_gridview.dart';

class HistoryScreen extends StatelessWidget {
  final String companyId;

  const HistoryScreen({super.key, required this.companyId});

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
        // 기존 정렬 로직 활용 (naturalSortCompare는 기존 MoveScreen에서 복사하여 사용 권장)

        return DefaultTabController(
          length: sections.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('테이블별 히스토리'),
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
                  .map((s) => HistoryGridView(companyId: companyId, section: s))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
