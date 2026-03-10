import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prost/class/app_user.dart';
import 'package:prost/class/table.dart';
import 'package:prost/class/table_repo.dart';
import 'package:prost/screens/move_screen.dart';

class InfoAlert extends StatefulWidget {
  final String companyId;
  final TableModel table;

  const InfoAlert({
    super.key,
    required this.companyId,
    required this.table,
  });

  @override
  State<InfoAlert> createState() => _TableRegistrationDialogState();
}

class _TableRegistrationDialogState extends State<InfoAlert> {
  // 입력 컨트롤러 정의
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bottleController;
  late TextEditingController _staffController;
  late TextEditingController _remarksController;
  late TextEditingController _personsController;
  final _repo = TableRepository();

  Future<AppUser?> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return AppUser.fromMap(doc.id, doc.data()!);
  }

  @override
  void initState() {
    super.initState();
    // [핵심] 테이블의 기존 정보를 컨트롤러의 초기값으로 설정합니다.
    // '미지정' 혹은 '없음'과 같은 기본값일 때는 빈 칸으로 보여줍니다.
    _nameController = TextEditingController(
      text: widget.table.customer == '손님 미지정' ? '' : widget.table.customer,
    );
    _phoneController = TextEditingController(
      text: widget.table.phonenumber == '번호 없음' ? '' : widget.table.phonenumber,
    );
    _bottleController = TextEditingController(
      text: widget.table.bottle == '바틀 미지정' ? '' : widget.table.bottle,
    );
    _personsController = TextEditingController(
      text: widget.table.persons == 0 ? '' : widget.table.persons.toString(),
    );
    _staffController = TextEditingController();
    _remarksController = TextEditingController(
      text: widget.table.staff == '비고 없음' ? '' : widget.table.remark,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bottleController.dispose();
    _staffController.dispose();
    _personsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchCurrentUser(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUser = userSnapshot.data!;

        if (_staffController.text.isEmpty) {
          if (widget.table.staff == '스태프 미지정' || widget.table.staff.isEmpty) {
            _staffController.text = currentUser.username;
          } else {
            _staffController.text = widget.table.staff;
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: AlertDialog(
            title: Text('${widget.table.tablename} 정보 등록'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '손님 이름'),
                    ),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: '손님 번호'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: _bottleController,
                      decoration: const InputDecoration(labelText: '구매 목록'),
                    ),
                    TextField(
                      controller: _personsController,
                      decoration: const InputDecoration(labelText: '인원'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: _staffController,
                      decoration: const InputDecoration(labelText: '담당 스태프'),
                    ),
                    TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(labelText: '비고(특이사항)'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TextButton(
                          onPressed: () async {
                            await _repo.clearTable(
                              widget.companyId,
                              widget.table.tid,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text(
                            '아웃',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context); // 현재 알림창 닫기
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MoveScreen(
                                  companyId: widget.companyId,
                                  fromTable: widget.table,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            '이동',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TextButton(
                          onPressed: () async {
                            // 필수 정보 입력 확인 (이름, 바틀 등)
                            if (_nameController.text.isNotEmpty ||
                                _bottleController.text.isNotEmpty ||
                                _phoneController.text.isNotEmpty ||
                                _remarksController.text.isNotEmpty ||
                                _personsController.text.isNotEmpty) {
                              await _repo.registerBottleKeep(
                                company: widget.companyId,
                                tid: widget.table.tid,
                                customer: _nameController.text.trim(),
                                phonenumber: _phoneController.text.trim(),
                                staff: _staffController.text.trim(),
                                persons:
                                    int.tryParse(
                                      _personsController.text.trim(),
                                    ) ??
                                    0, // 기존 인원 유지
                                bottle: _bottleController.text.trim(),
                                remark: _remarksController.text.trim(),
                              );
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          child: const Text('등록'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
