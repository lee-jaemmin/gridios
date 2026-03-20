import 'package:flutter/material.dart';
import 'package:prost/class/table_repo.dart';
import 'package:prost/class/table.dart';
import 'package:prost/screens/reregister_screen.dart';

class HistoryGridView extends StatelessWidget {
  final String companyId;
  final String section;
  final TableRepository _repo = TableRepository();

  HistoryGridView({super.key, required this.companyId, required this.section});

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
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _showHistoryBottomSheet(context, tables[index]),
            child: Card(
              child: Center(
                child: Text(
                  tables[index].tablename,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHistoryBottomSheet(BuildContext context, TableModel table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 높이 조절 가능하게 설정
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9, // 화면의 90% 채움
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${table.tablename} 히스토리',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder(
                stream: _repo.getTableHistoryStream(companyId, table.tid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final historyDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: historyDocs.length,
                    itemBuilder: (context, index) {
                      final h =
                          historyDocs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            '손님: ${h['customer']} (${h['persons']}명)',
                          ),
                          subtitle: Text(
                            '구매 목록: ${h['bottle']}\n전화 번호: ${h['phonenumber']}\n아웃 스태프: ${h['outstaff']}\n비고: ${h['remark']}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReregisterScreen(
                                  companyId: companyId,
                                  historyData: h,
                                ),
                              ),
                            ),
                            child: const Text('재등록'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
