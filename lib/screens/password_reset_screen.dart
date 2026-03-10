import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prost/constants/gaps.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 형식이 아닙니다.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Firebase 비밀번호 재설정 링크 전송
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('오류'),
              content: const Text('회원가입 되지 않은 이메일입니다. 이메일 주소를 다시 확인해주세요.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('전송 완료'),
            content: const Text('비밀번호 재설정 링크가 이메일로 발송되었습니다. 메일함을 확인해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // 로그인 화면으로 돌아가기
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('>>>>>> 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "가입 시 사용한 이메일을 입력해주세요.\n비밀번호 변경 링크를 보내드립니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            Gaps.v20(context),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            Gaps.v20(context),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("재설정 링크 보내기"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
