import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prost/class/appuser_repo.dart';
import 'package:prost/constants/gaps.dart';
import 'package:prost/main.dart' show flutterLocalNotificationsPlugin;
import 'package:prost/screens/password_reset_screen.dart';
import 'package:prost/widgets/agree_checkbox.dart';
import 'package:prost/widgets/auth_textfield.dart';
import 'package:prost/widgets/company_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart'; // 홈 화면 import 필요

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true; // true: 로그인 모드, false: 회원가입 모드
  bool isLoading = false; // 로딩 상태

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  final _formKey = GlobalKey<FormState>();
  final _userRepo = UserRepository();

  String? _selectedCompany;

  @override
  void initState() {
    super.initState();
    // 실시간 유효성 체크
    _passwordController.addListener(_validatePassword);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final text = _emailController.text.trim();
    if (text.isEmpty) {
      setState(() => _isEmailValid = true); // 비어있을 때는 경고를 띄우지 않음
      return;
    }

    // 이메일 정규식
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isValid = emailRegex.hasMatch(text);

    if (_isEmailValid != isValid) {
      setState(() => _isEmailValid = isValid);
    }
  }

  bool _isFormValid() {
    if (isLoading) return false;

    // 공통 조건: 이메일이 유효하고, 비어있지 않으며, 비밀번호가 유효해야 함
    final bool emailFilled = _emailController.text.trim().isNotEmpty;
    final bool passwordFilled = _passwordController.text.isNotEmpty;

    if (isLogin) {
      // 로그인 모드: 이메일과 비밀번호만 체크
      return emailFilled && passwordFilled;
    } else {
      // 회원가입 모드: 이메일 유효성 + 비밀번호 유효성 + 약관 동의 2종 + 이름/업장 입력 여부
      // _isEmailValid는 정규식을 통과했을 때만 true가 되도록 기존 로직을 따름
      return _isEmailValid &&
          emailFilled &&
          _isPasswordValid &&
          passwordFilled &&
          _agreedToTerms &&
          _agreedToPrivacy &&
          _nameController.text.trim().isNotEmpty && // 이름 입력 필수
          _companyController.text.trim().isNotEmpty; // 업장 선택 필수
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _validatePassword() {
    final isValid = _passwordController.text.length >= 6;
    if (_isPasswordValid != isValid) {
      setState(() => _isPasswordValid = isValid);
    }
  }

  // 제출 함수 (로그인 또는 회원가입)
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isLogin && (!_agreedToTerms || !_agreedToPrivacy)) return;

    setState(() => isLoading = true);

    // 사용자가 입력한 아이디를 이메일 형식으로 변환
    final String userEmail = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      if (isLogin) {
        // [로그인]
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail,
          password: password,
        );
        await _userRepo.updateFcmToken();
      } else {
        // [회원가입]
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: userEmail,
              password: password,
            );
        final companyName = _companyController.text.trim();
        final companyQuery = await FirebaseFirestore.instance
            .collection('company')
            .where('name', isEqualTo: companyName)
            .get();

        if (companyQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('존재하지 않는 회사입니다. 정확한 상업명을 입력해주세요.')),
          );
          return;
        }

        final companyDoc = companyQuery.docs.first;
        final companyId = companyDoc.id;
        final realCompanyName = companyDoc['name'];
        // Firestore 저장
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'username': _nameController.text.trim(), // 이름 저장
              'email': userEmail, // (참고용) 전체 이메일
              'id': _emailController.text.trim(),
              'companyid': companyId,
              'companyname': realCompanyName,
              'role': 'user',
              'createdAt': FieldValue.serverTimestamp(),
            });
        await _userRepo.updateFcmToken();
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "$e";

      // 사용자에게 보여줄 에러 메시지도 다듬어야 합니다.
      if (e.code == 'email-already-in-use') {
        message = "이미 사용 중인 아이디입니다.";
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = "아이디 또는 비밀번호가 잘못되었습니다.";
      } else if (e.code == 'invalid-email') {
        message = "아이디 형식이 올바르지 않습니다.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleCompanySelection() async {
    // Picker를 띄우고 사용자가 선택할 때까지 기다림(await)
    final selected = await CompanyPicker.show(context);

    if (selected != null) {
      setState(() {
        _selectedCompany = selected;
        _companyController.text = selected; // 텍스트 필드에도 표시
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "GRID",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isLogin
                        ? "실시간 테이블 현황 관리 및 효율적인 매장 운영을 위한 GRID 스태프 전용 서비스입니다. 제휴되지 않은 일반 사용자는 기능 이용이 제한됩니다."
                        : "구글 메일로 가입 시 비밀번호 찾기가 어려울 수 있습니다.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // 2. 입력 필드들
                  // [회원가입 전용] 이름
                  if (!isLogin)
                    AuthTextfield(
                      controller: _nameController,
                      hintText: "이름 (본명)",
                      icon: Icons.person_outline,
                    ),
                  if (!isLogin) const SizedBox(height: 16),

                  // [회원가입 전용] 업장명
                  if (!isLogin)
                    GestureDetector(
                      onTap: _handleCompanySelection, // 분리된 함수 호출
                      child: AbsorbPointer(
                        child: AuthTextfield(
                          controller: _companyController,
                          hintText: "업장을 선택해주세요",
                          icon: Icons.store_mall_directory_outlined,
                        ),
                      ),
                    ),
                  if (!isLogin) const SizedBox(height: 16),

                  // [공통] 아이디
                  AuthTextfield(
                    controller: _emailController,
                    hintText: "이메일",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  if (!_isEmailValid && _emailController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 15),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "올바른 이메일 형식이 아닙니다.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                  // [공통] 비밀번호
                  AuthTextfield(
                    controller: _passwordController,
                    hintText: "비밀번호",
                    icon: Icons.lock_outline,
                    obscureText: true,
                    suffixIcon: (_isPasswordValid && !isLogin)
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  if (!isLogin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 15),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isPasswordValid ? "" : "비밀번호는 6자리 이상으로 설정해주세요.",
                          style: TextStyle(
                            fontSize: 12,
                            color: _isPasswordValid ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),

                  if (!isLogin) ...[
                    const SizedBox(height: 24),
                    AgreeCheckbox(
                      title: "이용약관",
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                      onTapTitle: () => _launchURL(
                        "https://sites.google.com/view/grid-conditionterms?usp=sharing",
                      ),
                    ),
                    const SizedBox(height: 8),
                    AgreeCheckbox(
                      title: "개인정보처리방침",
                      value: _agreedToPrivacy,
                      onChanged: (v) =>
                          setState(() => _agreedToPrivacy = v ?? false),
                      onTapTitle: () => _launchURL(
                        "https://sites.google.com/view/gridprivatepolicy?usp=sharing",
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  // 3. 메인 버튼 (로그인 or 가입하기)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isFormValid() ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87, // 브랜드 컬러
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // 동글동글
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isLogin ? "로그인" : "회원가입",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 4. 모드 전환 버튼 (하단 회색 글씨)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLogin = !isLogin; // 모드 토글
                        _formKey.currentState?.reset(); // 폼 초기화
                      });
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(
                            isLogin ? "아직 계정이 없으신가요?" : "이미 계정이 있으신가요?",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          Gaps.h12(context),
                          Text(
                            isLogin ? "회원가입" : "로그인",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold, // [수정] 강조할 텍스트만 두껍게
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      if (isLogin) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PasswordResetScreen(),
                          ),
                        );
                      }
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(
                            isLogin ? "비밀번호를 잊어버리셨나요?" : "",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          Gaps.h12(context),
                          Text(
                            isLogin ? "비밀번호 재설정" : "",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
