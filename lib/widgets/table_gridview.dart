import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';
import 'package:prost/widgets/table_card.dart';

class TableGridView extends StatelessWidget {
  final String companyid;
  final String section;
  final TableRepository _repo = TableRepository();

  TableGridView({required this.companyid, required this.section});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TableModel>>(
      stream: _repo.getTablesStream(companyid, section), // 실시간 데이터 수신
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("오류 발생: ${snapshot.error}"));
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final tables = snapshot.data!;

        return GridView.builder(
          padding: EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 한 줄에 3개씩 배치
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return TableCard(companyId: companyid, table: table);
          },
        );
      },
    );
  }
}
