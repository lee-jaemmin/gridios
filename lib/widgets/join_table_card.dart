import 'package:flutter/material.dart';
import 'package:prost/class/table.dart';

class JoinTableCard extends StatelessWidget {
  final TableModel table;
  final bool isSelectedMaster; // 현재 마스터로 선택되었는지
  final bool isSelectedSlave; // 현재 슬레이브로 선택되었는지
  final VoidCallback onTap;

  const JoinTableCard({
    super.key,
    required this.table,
    required this.isSelectedMaster,
    required this.isSelectedSlave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // [상태 판별 로직]
    // 1. 이미 합석된 그룹인지 확인
    final bool isAlreadyJoined = table.groupid != null;
    final bool isExistingMaster = table.ismaster;

    // 2. 카드 배경색 결정
    Color cardColor;
    Color textColor = Colors.black;

    if (isSelectedMaster) {
      cardColor = Colors.redAccent; // 선택된 마스터 (빨강)
      textColor = Colors.white;
    } else if (isSelectedSlave) {
      cardColor = Colors.green; // 선택된 슬레이브 (초록)
      textColor = Colors.white;
    } else if (isAlreadyJoined) {
      // 이미 합석된 테이블은 구분 (예: 앰버/오렌지)
      cardColor = isExistingMaster ? Colors.orangeAccent : Colors.orange[100]!;
    } else if (table.status == 'inuse') {
      // 사용 중이지만 합석은 아닌 테이블 (슬레이브 선택 불가)
      cardColor = Colors.grey[400]!;
      textColor = Colors.grey[800]!;
    } else {
      // 빈 테이블 (기본)
      cardColor = Colors.grey[100]!;
    }

    return Card(
      color: cardColor,
      elevation: (isSelectedMaster || isSelectedSlave) ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: (isSelectedMaster || isSelectedSlave)
            ? BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 테이블 이름
              Text(
                table.tablename,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),

              // 상태 텍스트 표시
              if (isSelectedMaster)
                const Text(
                  'NEW MASTER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              else if (isSelectedSlave)
                const Text(
                  'NEW SLAVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              else if (table.status == 'inuse')
                const Text(
                  '사용중',
                  style: TextStyle(fontSize: 12),
                )
              else
                const Text(
                  '선택 가능',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
