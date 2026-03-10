import 'package:prost/class/table.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class TableRepository {
  final FirebaseFirestore _db;

  TableRepository({
    FirebaseFirestore? db,
    auth.FirebaseAuth? authInstance,
  }) : _db = db ?? FirebaseFirestore.instance;

  /// return the address of 'collection' the group of doc.
  CollectionReference<Map<String, dynamic>> _tableCol(String company) {
    return _db.collection('company').doc(company).collection('tables');
  }

  // 2차 오름차순 정렬. A10 문제 해결
  int _naturalSort(String a, String b) {
    // 정규표현식으로 문자와 숫자를 분리 (예: A1 -> ['A', '1'])
    final regExp = RegExp(r'([A-Za-z]+)|(\d+)');
    final matchesA = regExp.allMatches(a).toList();
    final matchesB = regExp.allMatches(b).toList();

    for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
      final strA = matchesA[i].group(0)!;
      final strB = matchesB[i].group(0)!;

      // 둘 다 숫자인 경우 숫자로 비교
      if (int.tryParse(strA) != null && int.tryParse(strB) != null) {
        int numA = int.parse(strA);
        int numB = int.parse(strB);
        if (numA != numB) return numA.compareTo(numB);
      } else {
        // 문자인 경우 문자열로 비교
        int res = strA.compareTo(strB);
        if (res != 0) return res;
      }
    }
    return a.length.compareTo(b.length);
  }

  /// live stream
  Stream<List<TableModel>> getTablesStream(String company, String section) {
    return _tableCol(
          company,
        )
        .where('section', isEqualTo: section)
        .orderBy('tablename', descending: false)
        .snapshots()
        .map((snap) {
          final List<TableModel> tableList = snap.docs.map((doc) {
            final Map<String, dynamic> data = doc.data();
            final String id = doc.id;
            return TableModel.fromMap(id, data);
          }).toList();
          tableList.sort((a, b) => _naturalSort(a.tablename, b.tablename));
          return tableList;
        });
  }

  /* 
  .map(
          (snap) => snap.docs
              .map((doc) => TableModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  */

  /// [ADD] create table
  Future<void> createTable({
    required String company,
    required String tablename,
    required String section,
    required String customer,
    required String phonenumber,
    required String bottle,
    required String status,
    required String remark,
    required int persons,
    required String staff,
  }) async {
    // 저장할 위치(문서 참조)를 먼저 정해서 tid 확보
    final docRef = _tableCol(company).doc();
    final newTable = TableModel(
      tid: docRef.id,
      tablename: tablename,
      section: section,
      customer: customer,
      phonenumber: phonenumber,
      bottle: bottle,
      staff: staff,
      persons: persons,
      remark: remark,
      status: 'available',
      createdat: DateTime.now(),
    );

    // store on DB
    await docRef.set(
      {...newTable.toMap(), 'createdat': FieldValue.serverTimestamp()},
    );
  }

  /// [OUT] Out table
  Future<void> clearTable(String company, String tid) async {
    // 1. 해당 테이블의 현재 데이터를 먼저 가져와 groupid 확인
    final doc = await _tableCol(company).doc(tid).get();
    final data = doc.data();
    if (data == null) return;

    final historyData = {
      'tablename': data['tablename'],
      'customer': data['customer'],
      'phonenumber': data['phonenumber'],
      'bottle': data['bottle'],
      'persons': data['persons'],
      'staff': data['staff'],
      'remark': data['remark'],
      'outat': FieldValue.serverTimestamp(), // 아웃 시점 기록
    };

    final String? groupid = data['groupid'];
    final batch = _db.batch(); // 일괄 처리를 위한 배치 생성

    final historyRef = _tableCol(company).doc(tid).collection('history').doc();
    batch.set(historyRef, historyData);

    if (groupid != null) {
      // 합석 중인 경우 해당 groupid를 공유하는 모든 테이블을 찾음
      final snapshot = await _tableCol(
        company,
      ).where('groupid', isEqualTo: groupid).get();

      for (var tableDoc in snapshot.docs) {
        if (tableDoc.id == tid) {
          //  지금 아웃시키는 테이블의 모든 정보 초기화
          batch.update(tableDoc.reference, {
            'status': 'available',
            'customer': '',
            'phonenumber': '',
            'staff': '',
            'bottle': '',
            'remark': '',
            'persons': 0,
            'groupid': FieldValue.delete(),
            'ismaster': FieldValue.delete(),
            'mastertablenumber': FieldValue.delete(),
            'updatedat': FieldValue.serverTimestamp(),
          });
        } else {
          // 같은 그룹이었던 다른 테이블들은 합석 관계만 끊고 기록/상태는 유지
          batch.update(tableDoc.reference, {
            'groupid': FieldValue.delete(),
            'ismaster': FieldValue.delete(),
            'mastertablenumber': FieldValue.delete(),
            'updatedat': FieldValue.serverTimestamp(),
          });
        }
      }
    } else {
      // 합석 중이 아니면 해당 테이블만 정상적으로 초기화
      batch.update(_tableCol(company).doc(tid), {
        'status': 'available',
        'customer': '',
        'phonenumber': '',
        'staff': '',
        'bottle': '',
        'remark': '',
        'persons': 0,
        'groupid': FieldValue.delete(),
        'ismaster': FieldValue.delete(),
        'mastertablenumber': FieldValue.delete(),
        'updatedat': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit(); // 모든 변경 사항을 한 번에 적용
  }

  /// [HISTORY] 특정 테이블의 히스토리 가져오기
  Stream<QuerySnapshot> getTableHistoryStream(String company, String tid) {
    return _tableCol(company)
        .doc(tid)
        .collection('history')
        .orderBy('outat', descending: true)
        .snapshots();
  }

  /// [MOVE] 테이블 이동 처리 (A -> B)
  /// 트랜잭션을 이용하여 Race Condition 방지.
  Future<void> moveTable(
    String company,
    TableModel fromTable,
    String toTid,
  ) async {
    // 트랜잭션은 읽기 작업이 쓰기 작업보다 선행되어야.
    await _db.runTransaction((transaction) async {
      final toTableRef = _tableCol(company).doc(toTid);
      final fromTableRef = _tableCol(company).doc(fromTable.tid);

      // 대상 테이블의 최신 상태를 읽음
      final toTableSnapshot = await transaction.get(toTableRef);

      if (!toTableSnapshot.exists) {
        throw Exception("대상 테이블이 존재하지 않습니다.");
      }

      final toTableData = toTableSnapshot.data()!;

      // 대상 테이블이 여전히 'available'인지 검사
      if (toTableData['status'] != 'available') {
        throw Exception("ALREADY_IN_USE"); // 이미 사용 중이면 중단
      }

      // 이동
      transaction.update(toTableRef, {
        'status': 'inuse',
        'customer': fromTable.customer,
        'phonenumber': fromTable.phonenumber,
        'staff': fromTable.staff,
        'bottle': fromTable.bottle,
        'remark': fromTable.remark,
        'persons': fromTable.persons,
        'updatedat': FieldValue.serverTimestamp(),
      });

      // 기존 테이블 초기화
      transaction.update(fromTableRef, {
        'status': 'available',
        'customer': '',
        'phonenumber': '',
        'staff': '',
        'bottle': '',
        'remark': '',
        'persons': 0,
        'updatedat': FieldValue.serverTimestamp(),
      });
    });
  }

  /// [RES] 예약 시간 업데이트
  Future<void> updateReservation(
    String company,
    String tid,
    String? time,
  ) async {
    await _tableCol(company).doc(tid).update({
      'reservationtime': time,
      'updatedat': FieldValue.serverTimestamp(),
    });
  }

  /// [DEL] Delete table
  Future<void> deleteTable(String company, String tid) async {
    await _tableCol(company).doc(tid).delete();
  }

  /// [MOD] modify tablename or section
  Future<void> updateTableLayout(
    String company,
    String tid,
    Map<String, dynamic> patch,
  ) async {
    await _tableCol(company).doc(tid).update({
      ...patch,
      'updatedat': FieldValue.serverTimestamp(),
    });
  }

  /// [JOIN] join.
  Future<void> joinGroup({
    required String company,
    required TableModel master,
    required List<TableModel> slaves,
  }) async {
    final batch = _db.batch();
    final String newGroupid = master.tid;

    // 마스터 테이블 업데이트 (대장)
    batch.update(_tableCol(company).doc(master.tid), {
      'groupid': newGroupid,
      'ismaster': true,
      'updatedat': FieldValue.serverTimestamp(),
    });

    // 슬레이브 테이블 일괄 업데이트 (정보 상속)
    // 마스터의 정보를 그대로 복사하여 '사용 중' 상태로.
    for (var slave in slaves) {
      batch.update(_tableCol(company).doc(slave.tid), {
        'status': 'inuse',
        'groupid': newGroupid,
        'ismaster': false,
        'mastertablenumber': master.tablename,

        // 마스터 정보 상속
        'customer': master.customer,
        'phonenumber': master.phonenumber,
        'staff': master.staff,
        'bottle': master.bottle,
        'remark': '${master.tablename}번 합석',
        'persons': master.persons,
        'updatedat': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// [UNJOIN] 합석 해제 (그룹 전체 해산)
  Future<void> unjoinGroup({
    required String company,
    required String groupid,
  }) async {
    // 해당 그룹 ID를 가진 모든 테이블 조회
    final snapshot = await _tableCol(
      company,
    ).where('groupid', isEqualTo: groupid).get();

    final batch = _db.batch();

    for (var doc in snapshot.docs) {
      // 해당 문서가 마스터인지 확인 (데이터 필드 기준)
      final bool ismaster = doc.data()['ismaster'] == true;

      if (ismaster) {
        // 마스터는 정보(손님, 바틀 등)는 유지하고 합석 상태만 해제.
        batch.update(doc.reference, {
          'groupid': FieldValue.delete(),
          'ismaster': FieldValue.delete(),
          'updatedat': FieldValue.serverTimestamp(),
        });
      } else {
        // 슬레이브 테이블: 정보 삭제, 'available' 상태로 초기화
        batch.update(doc.reference, {
          'groupid': FieldValue.delete(),
          'ismaster': FieldValue.delete(),
          'mastertablenumber': FieldValue.delete(),
          'updatedat': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// [ACT] activation table: 여기가 사실상 정보 입력 하는 부분.
  Future<void> registerBottleKeep({
    required String company,
    required String tid,
    required String customer, // 손님 이름
    required String phonenumber, // 손님 번호
    required String staff, // 담당 직원
    required int persons,
    required String remark,
    required String bottle, // 술 종류
  }) async {
    await _tableCol(company).doc(tid).update({
      'customer': customer,
      'phonenumber': phonenumber,
      'staff': staff,
      'bottle': bottle,
      'status': 'inuse', // 정보가 입력되면 상태를 'inuse'로 변경
      'persons': persons,
      'remark': remark,
      'updatedat': FieldValue.serverTimestamp(), // 수정 시간 기록
    });
  }

  /// [섹션] 섹션 목록 추가
  Future<void> addSection(String companyId, String sectionName) async {
    await _db.collection('company').doc(companyId).update({
      'sections': FieldValue.arrayUnion([sectionName]),
    });
  }

  /// [섹션] 섹션 목록 삭제
  Future<void> removeSection(String companyId, String sectionName) async {
    await _db.collection('company').doc(companyId).update({
      'sections': FieldValue.arrayRemove([sectionName]),
    });
  }
}
