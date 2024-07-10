import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:kakaotest/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  OAuthToken? token;
  bool isFirstLogin = false;

  Future<void> sendUserInfoToBackend(String accessToken, User user) async {
    String? ip = dotenv.env['ip'];
    final url = Uri.parse('http://${ip}:3000/api/login');

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            SystemNavigator.pop();
          },
        )
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              Text("간편로그인 후", style: TextStyle(fontFamily: 'Elice', fontSize: 25)),
              Text("이용이", style: TextStyle(fontFamily: 'Elice', fontSize: 25)),
              Text("가능합니다.", style: TextStyle(fontFamily: 'Elice', fontSize: 25)),
          SizedBox(height: 100),
          Align(
            alignment: Alignment.center,
              child: Image.asset("assets/kickin.png", width: 200, height: 200,)),
          SizedBox(height: 60),
          Center(
            child: InkWell(
              onTap: () {
                signInWithKakao();
              },
              child: Image.asset(
                'assets/kakao_login_large_wide.png',
              ),
            ),
          ),
        ],
      ),
    )
    );
  }
}