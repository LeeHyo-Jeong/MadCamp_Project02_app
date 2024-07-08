import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:kakaotest/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  OAuthToken? token;
  bool isFirstLogin = false;

  Future<void> sendUserInfoToBackend(String accessToken, User user) async {
    final url = Uri.parse('http://localhost:3000/api/login');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'access_token': accessToken,
        'user_id': user.id.toString(),
        'image_url': user.kakaoAccount?.profile?.profileImageUrl,
        'profile_nickname': user.kakaoAccount?.profile?.nickname,
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      isFirstLogin = result['isFirstLogin'];

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MyHomePage(user: user, isFirstLogin: isFirstLogin),
        ),
      );
    } else {
      print("Failed to send user info to backend: ${response.statusCode}");
    }
  }

  Future<void> _storeToken(OAuthToken token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("kakao_access_token", token.accessToken);
    await TokenManagerProvider.instance.manager.setToken(token);
  }

  Future<void> signInWithKakao() async {
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
        User user = await UserApi.instance.me();
        await _storeToken(token!);
        await sendUserInfoToBackend(token!.accessToken, user);
      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');

        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }

        try {
          token = await UserApi.instance.loginWithKakaoAccount();
          User user = await UserApi.instance.me();
          await _storeToken(token!);
          await sendUserInfoToBackend(token!.accessToken, user);
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
        }
      }
    } else {
      try {
        token = await UserApi.instance.loginWithKakaoAccount();
        User user = await UserApi.instance.me();
        await _storeToken(token!);
        await sendUserInfoToBackend(token!.accessToken, user);
      } catch (error) {
        print('카카오계정으로 로그인 실패 $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: InkWell(
          onTap: () {
            signInWithKakao();
          },
          child: Image.asset(
            'assets/kakao_login_large_wide.png',
          ),
        ),
      ),
    );
  }
}