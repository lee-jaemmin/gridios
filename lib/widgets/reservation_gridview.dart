import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';
import 'package:prost/widgets/reservation_card.dart';

class ReservationGridView extends StatelessWidget {
  final String companyId;
  final String section;
  final Function(TableModel) onTableTap;
  final TableRepository _repo = TableRepository();

  ReservationGridView({
    required this.companyId,
    required this.section,
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
            return ReservationCard(
              companyId: companyId,
              table: table,
              onTap: () => onTableTap(table),
            );
          },
        );
      },
    );
  }
}
