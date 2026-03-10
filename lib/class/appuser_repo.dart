import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:prost/class/app_user.dart';

class UserRepository {
  final FirebaseFirestore _db;
  final auth.FirebaseAuth _auth;

  UserRepository({
    FirebaseFirestore? db,
    auth.FirebaseAuth? authInstance,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = authInstance ?? auth.FirebaseAuth.instance;
  // init list: set field at a time when instance is created

  /// 이미 있는 데이터: 냅둠, 새 데이터: db에 등록
  Future<void> upsertFromAuth({
    required String companyid,
    required String username,
    required String companyname,
    required bool isAdmin,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null)
      throw StateError('로그인이 필요합니다. ERROR CODE: currentUser is null');

    // create AppUser instance using company, username from outside
    final appUser = AppUser.fromFirebase(
      currentUser,
      companyid: companyid,
      companyname: companyname,
      isAdmin: isAdmin,
      username: username,
    );

    final ref = _db.collection('users').doc(currentUser.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      // 신규 가입 시 모든 정보 저장
      await ref.set({
        ...appUser.toMap(),

        //...: {}안에 내용 물 꺼내기.
      });
    } else {
      // 바뀔 수 있을 만한 정보만 업데이트
      await ref.update({
        'username': username,
        'companyid': companyid,
        'companyname': companyname,
      });
    }
  }

  Future<void> updateFcmToken() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 1. 기기의 고유 토큰 가져오기
    String? token = await FirebaseMessaging.instance.getToken();

    // 2. 토큰이 있다면 Firestore의 해당 유저 문서에 업데이트
    if (token != null) {
      await _db.collection('users').doc(currentUser.uid).update({
        'fcmtoken': token,
      });
      print("FCM 토큰 업데이트 성공: $token");
    }
  }
}
