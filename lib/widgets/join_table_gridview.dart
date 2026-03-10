import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';
import 'package:prost/widgets/join_table_card.dart';

class JoinTableGridView extends StatelessWidget {
  final String companyId;
  final String section;
  final String? selectedMasterId;
  final List<String> selectedSlaveIds;
  final Function(TableModel) onTableTap; // ReservationGridView와 동일한 구조
  final TableRepository _repo = TableRepository();

  JoinTableGridView({
    super.key,
    required this.companyId,
    required this.section,
    required this.selectedMasterId,
    required this.selectedSlaveIds,
    required this.onTableTap,
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
            final table = tables[index];
            return JoinTableCard(
              table: table,
              isSelectedMaster: table.tid == selectedMasterId,
              isSelectedSlave: selectedSlaveIds.contains(table.tid),
              onTap: () => onTableTap(table), // 넘겨받은 콜백 실행
            );
          },
        );
      },
    );
  }
}
