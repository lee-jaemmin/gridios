import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/widgets/info_alert.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final String companyId;

  TableCard({required this.table, required this.companyId});

  bool _isReservationValid(String? resTime) {
    if (resTime == null || resTime.isEmpty || resTime == '예약 없음') return false;

    try {
      final now = DateTime.now();
      final parts = resTime.split(':');
      // 오늘의 연/월/일과 예약의 시/분을 결합하여 비교
      final resDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return now.isBefore(resDateTime);
    } catch (e) {
      return false; // 형식 오류 시 표시 안 함
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showRes = _isReservationValid(table.reservationTime);
    return Stack(
      children: [
        Card(
          color: table.status == 'available'
              ? Colors.grey[200]
              : const Color.fromARGB(255, 230, 207, 200),
          child: InkWell(
            onTap: () {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) =>
                    InfoAlert(companyId: companyId, table: table),
              );
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.tablename,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                  ),
                  if (table.bottle.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      table.bottle,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${table.persons}명',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        if (showRes)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                table.reservationTime!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
