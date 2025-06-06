import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_view_model.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _autoLogin = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);

    ref.listen<LoginState>(loginViewModelProvider, (prev, next) {
      if (next.status == LoginStatus.success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (next.status == LoginStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message ?? '로그인 실패')),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child:
              Column(
              children: [
                const Spacer(),
                Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 42,
                    color: secondaryColor.withOpacity(0.6),
                    fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  'CBA',
                  style: TextStyle(
                    fontSize: 68,
                    fontWeight: FontWeight.bold,
                    color: secondarySub1Color
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _idCtrl,
                  style: TextStyle(color: text900Color),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '아이디',
                    hintStyle: TextStyle(color: text600Color),
                    prefixIcon: Icon(Icons.person, color: secondarySub1Color),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: primarySub1Color),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide:
                          BorderSide(color: secondarySub2Color),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: secondaryColor),
                    ),
                  ),
                  validator: (v) => v!.isNotEmpty ? null : '아이디를 입력하세요',
                ),

                const SizedBox(height: 16),

                // 3) 비밀번호 입력
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: TextStyle(color: text900Color),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '비밀번호',
                    hintStyle: TextStyle(color: text600Color),
                    prefixIcon: Icon(Icons.lock, color: secondarySub1Color),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primarySub1Color),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide:
                          BorderSide(color: secondarySub2Color),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: secondaryColor),
                    ),
                  ),
                  validator: (v) =>
                      (v?.length ?? 0) >= 6 ? null : '6자 이상 입력하세요',
                ),

                const SizedBox(height: 16),

                // 4) 로그인 버튼
                state.status == LoginStatus.loading
                    ? CircularProgressIndicator(color: secondarySub1Color)
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondarySub1Color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ref
                                  .read(loginViewModelProvider.notifier)
                                  .login(_idCtrl.text, _passwordCtrl.text, _autoLogin);
                            }
                          },
                          child: Text(
                            '로그인',
                            style: TextStyle(fontSize: 18, color: text200Color),
                          ),
                        ),
                      ),

                const SizedBox(height:8),

                // 5) 로그인 유지 체크박스
                Row(
                  children: [
                    Checkbox(
                      value: _autoLogin,
                      onChanged: (v) => setState(() => _autoLogin = v!),
                      activeColor: secondarySub1Color,
                    ),
                    Text(
                      '로그인 유지',
                      style: TextStyle(
                        color: text800Color,
                        fontSize: 18
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // 웹사이트 연결
                      },
                      child: Text(
                        '아이디/비밀번호 찾기',
                        style: TextStyle(
                          color: text700Color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        // 웹사이트 연결
                      },
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          color: text700Color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(), // 하단 여백
              ],
            ),
          )
        ),
      ),
    );

  }
}
