import 'package:flutter/material.dart';
import 'package:cba_connect_application/core/color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
  void initState() {
    super.initState();
    // 빌드가 끝난 뒤 한 프레임 뒤에 실행
    Future.microtask(() {
      ref.read(loginViewModelProvider.notifier).refreshLogin();
    });
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);

    ref.listen<LoginState>(loginViewModelProvider, (prev, next) {
      if (next.status == LoginStatus.success) {
        Navigator.pushReplacementNamed(context, '/main');
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
                        launchUrl(Uri.parse("https://recba.me/reset-password"));
                      },
                      child: Text(
                        '비밀번호 재설정',
                        style: TextStyle(
                          color: text700Color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        launchUrl(Uri.parse("https://recba.me/register"));
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
                const Spacer(),
              ],
            ),
          )
        ),
      ),
    );

  }
}
