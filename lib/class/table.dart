import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String tid;
  final String tablename;
  final String section;
  final String status;
  final String customer;
  final String phonenumber;
  final String staff;
  final String bottle;
  final String remark;
  final int persons;
  final String? reservationTime;
  final DateTime createdat;
  final String? groupid;
  final bool ismaster;
  final String? mastertablenumber;

  const TableModel({
    required this.tid,
    required this.tablename,
    required this.section,
    required this.status,
    required this.customer,
    required this.phonenumber,
    required this.staff,
    required this.bottle,
    required this.persons,
    required this.remark,
    this.reservationTime,
    this.groupid,
    this.ismaster = false,
    this.mastertablenumber,
    required this.createdat,
  });

  TableModel copyWith({
    String? tablename,
    String? section,
    String? status,
    String? customer,
    String? phonenumber,
    String? staff,
    String? bottle,
    int? persons,
    String? remark,
    String? reservationTime,
    String? groupid,
    bool? ismaster,
    String? mastertablenumber,
    DateTime? createdat,
  }) {
    return TableModel(
      tid: this.tid,
      tablename: tablename ?? this.tablename,
      section: section ?? this.section,
      status: status ?? this.status,
      customer: customer ?? this.customer,
      phonenumber: phonenumber ?? this.phonenumber,
      staff: staff ?? this.staff,
      bottle: bottle ?? this.bottle,
      persons: persons ?? this.persons,
      remark: remark ?? this.remark,
      reservationTime: reservationTime ?? this.reservationTime,
      groupid: groupid ?? this.groupid,
      ismaster: ismaster ?? this.ismaster,
      mastertablenumber: mastertablenumber ?? this.mastertablenumber,
      createdat: createdat ?? this.createdat,
    );
  }

  factory TableModel.fromMap(String tid, Map<String, dynamic> map) {
    return TableModel(
      tid: tid,
      tablename: map['tablename'] ?? '테이블 미지정',
      section: map['section'] ?? '섹션 미지정',
      status: map['status'] ?? '상태 미지정',
      customer: map['customer'] ?? '손님 미지정',
      phonenumber: map['phonenumber'] ?? '번호 없음',
      staff: map['staff'] ?? '',
      bottle: map['bottle'] ?? '',
      persons: map['persons'] ?? 0,
      remark: map['remark'] ?? '비고 없음',
      reservationTime: map['reservationtime'] ?? '',
      groupid: map['groupid'],
      ismaster: map['ismaster'] ?? false,
      mastertablenumber: map['mastertablenumber'],
      createdat: (map['createdat'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tablename': tablename,
      'section': section,
      'status': status,
      'customer': customer,
      'phonenumber': phonenumber,
      'staff': staff,
      'bottle': bottle,
      'persons': persons,
      'remark': remark,
      'reservationtime': reservationTime,
      'groupid': groupid,
      'ismaster': ismaster,
      'mastertablenumber': mastertablenumber,
      'createdat': createdat,
    };
  }
}
