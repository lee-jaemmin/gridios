import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';

class ReservationCard extends StatelessWidget {
  final String companyId;
  final TableModel table;
  final VoidCallback onTap;
  final TableRepository _repo = TableRepository();

  ReservationCard({
    super.key,
    required this.companyId,
    required this.table,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 예약 정보가 있는지 확인
    final bool hasReservation =
        table.reservationTime != null &&
        table.reservationTime!.isNotEmpty &&
        table.reservationTime != '예약 없음';

    return Stack(
      children: [
        Card(
          // 예약이 있으면 하늘색, 없으면 하얀색 계열
          color: hasReservation ? Colors.blue : Colors.grey[100],
          elevation: hasReservation ? 4 : 1,
          child: InkWell(
            onTap: onTap,
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
                  ),
                  const SizedBox(height: 8),

                  if (hasReservation)
                    Text(
                      table.reservationTime!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const Text(
                      '예약 없음',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ),

        if (hasReservation)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () async {
                // 예약 취소 확인 팝업
                bool confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('예약 취소'),
                    content: Text('${table.tablename}번 테이블의 예약을 취소하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('아니오'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('네'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _repo.updateReservation(companyId, table.tid, null); //
                }
              },
              child: const Icon(
                Icons.remove_circle,
                color: Colors.red,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }
}
