import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class AppUser {
  final String uid;
  final String username;
  final String companyid;
  final String companyname;
  final bool isAdmin;
  final DateTime createdat;
  final String? fcmToken;

  const AppUser({
    // const: All field has to be final
    // use memory only once
    required this.uid,
    required this.username,
    required this.companyid,
    required this.companyname,
    required this.isAdmin,
    required this.createdat,
    this.fcmToken,
  });

  AppUser copyWith({
    // bc of final fields can't moidfied
    // make copied new instance(changed only certatin field)
    //-------------------------------------------------------
    String? username,
    String? companyid,
    String? companyname,
    bool? isAdmin,
    DateTime? createdat,
    final String? fcmToken,
    // nullable: to choose only field that I want to modify
  }) {
    return AppUser(
      uid: this.uid,
      username: username ?? this.username,
      companyid: companyid ?? this.companyid,
      companyname: companyname ?? this.companyname,
      isAdmin: isAdmin ?? false,
      createdat: createdat ?? this.createdat,
      fcmToken: fcmToken ?? this.fcmToken,
      // if modified: modified field, else: same value
    );
  }

  /// 1. creation based on Firebase Auth
  factory AppUser.fromFirebase(
    auth.User user, {
    required String companyid,
    required String username,
    required String companyname,
    required bool isAdmin,
  }) {
    // factory: smart initializer; return instance according to logic I assign
    // inside {}: named parameter, outside {}: positional parameter

    return AppUser(
      uid: user.uid,
      username: username,
      companyid: companyid,
      companyname: companyname,
      isAdmin: isAdmin,
      createdat: DateTime.now(),
    );
  }

  /// 2. restoraion through Firestore data
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      username: map['username'] ?? '이름 미지정',
      companyid: map['companyid'] ?? '회사id 미지정',
      companyname: map['companyname'] ?? '회사 미지정',
      isAdmin: map['isAdmin'] ?? false,
      fcmToken: map['fcmtoken'],
      createdat: (map['createdat'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 3. transformation for Firestore save
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'companyid': companyid,
      'companyname': companyname,
      'createdat': createdat,
      'fcmtoken': fcmToken,
    };
  }
}
