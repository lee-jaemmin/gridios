import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:prost/class/app_user.dart';
import 'package:prost/constants/gaps.dart';
import 'package:prost/methods/check_admin.dart';
import 'package:prost/screens/history_screen.dart';
import 'package:prost/screens/join_screen.dart';
import 'package:prost/screens/login_screen.dart';
import 'package:prost/screens/table_management_screen.dart';
import 'package:prost/screens/table_reservation_screen.dart';
import 'package:prost/widgets/sidebar_menu.dart';
import 'package:prost/widgets/table_gridview.dart';

/// FirebaseAuth.instance.currentUser로 UID 획득
/// -> Firestore에서 해당 UID 문서 조회
/// -> AppUser.fromMap으로 변환 -> UI에서 사용
class HomeScreen extends StatelessWidget {
  Future<AppUser?> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser; // User 객체.
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return AppUser.fromMap(doc.id, doc.data()!);
  }

  // scaffold key to open side bar safely
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // logout Function
  Future<void> signOutAndNavigate(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // 모든 이전 라우트를 제거 (false 반환)
        );
      }
    } catch (e) {
      print("로그아웃 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')),
      );
    }
  }

  // 탈퇴 function
  Future<void> withdrawMembership(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('user가 존재하지 않습니다')),
      );
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .delete();

      await user.delete();

      if (context.mounted) {
        _showWithdrawSuccessDialog(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('보안을 위해 다시 로그인 후 탈퇴를 진행해주세요.')),
          );
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("탈퇴 오류: $e");
    }
  }

  void _showWithdrawSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 확인 버튼을 눌러야만 나갈 수 있게 설정
      builder: (context) => AlertDialog(
        title: const Text('탈퇴 완료'),
        content: const Text(
          '회원 탈퇴가 완료되었습니다. 모든 개인정보와 식별 데이터가 즉시 삭제되었으며, 더 이상 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 모든 페이지를 제거하고 로그인 화면으로 이동
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 탈퇴 문구
  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '애플 앱스토어 규정 및 2026 보안 가이드라인에 따라, 탈퇴 즉시 귀하의 모든 개인정보와 식별 데이터는 서버에서 영구 삭제(익명화)됩니다. '
          '탈퇴 보류 기간이 없으므로 삭제된 데이터는 복구할 수 없습니다. 정말 탈퇴하시겠습니까?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              withdrawMembership(context);
            },
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _fetchCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final currentUser = snapshot.data!;

        // StreamBuilder를 사용하여 DB를 실시간 구독
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('company') // 관리자 화면과 컬렉션명을 맞춤
              .doc(currentUser.companyid)
              .snapshots(),
          builder: (context, companySnapshot) {
            if (companySnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // DB에서 섹션 목록 가져오기
            final companyData =
                companySnapshot.data?.data() as Map<String, dynamic>?;
            final List<String> sections = List<String>.from(
              companyData?['sections'] ?? [],
            );
            sections.sort((a, b) => naturalSortCompare(a, b));

            return DefaultTabController(
              key: ValueKey(sections.length), // 섹션 개수가 변할 때 TabBar를 강제 새로고침
              length: sections.length,
              child: Scaffold(
                key: _scaffoldKey,
                endDrawer: Drawer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 100.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SidebarMenu(
                            name: '테이블 배치 관리',
                            onTapFunc: () => CheckAdminAndNavigate(
                              context: context,
                              designatedPage: TableManagementScreen(
                                company: currentUser.companyid,
                              ),
                            ),
                          ),
                          Gaps.v20(context),
                          SidebarMenu(
                            name: '예약',
                            onTapFunc: () => CheckAdminAndNavigate(
                              context: context,
                              designatedPage: const TableReservationScreen(),
                            ),
                          ),
                          Gaps.v20(context),
                          SidebarMenu(
                            name: '합석 관리',
                            onTapFunc: () {
                              Navigator.pop(context); // 드로어 닫기
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JoinScreen(
                                    companyId: currentUser.companyid,
                                  ),
                                ),
                              );
                            },
                          ),
                          Gaps.v20(context),
                          SidebarMenu(
                            name: '히스토리',
                            onTapFunc: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HistoryScreen(
                                    companyId: currentUser.companyid,
                                  ),
                                ),
                              );
                            },
                          ),
                          Gaps.v20(context),
                          SidebarMenu(
                            name: '로그아웃',
                            onTapFunc: () => signOutAndNavigate(context),
                          ),
                          Gaps.v20(context),
                          SidebarMenu(
                            name: '회원 탈퇴',
                            onTapFunc: () => _showWithdrawDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                appBar: AppBar(
                  title: Text('${currentUser.companyname} Dashboard'), //
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                        child: const Icon(FontAwesomeIcons.bars),
                      ),
                    ),
                  ],
                  // DB에서 가져온 섹션들로 탭 생성
                  bottom: sections.isEmpty
                      ? null
                      : TabBar(
                          indicatorWeight: 4,
                          labelStyle: TextStyle(fontSize: 16),
                          labelPadding: EdgeInsets.symmetric(horizontal: 20.0),
                          tabAlignment: TabAlignment.start,
                          isScrollable: true,
                          tabs: sections.map((s) => Tab(text: s)).toList(),
                        ),
                ),
                body: sections.isEmpty
                    ? const Center(
                        child: Text('설정된 섹션이 없습니다. 관리자 모드에서 추가해주세요.'),
                      )
                    : TabBarView(
                        children: sections.map((section) {
                          return TableGridView(
                            companyid: currentUser.companyid, //
                            section: section,
                          );
                        }).toList(),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
