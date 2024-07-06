import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  OAuthToken? token;

  Future<void> sendUserInfoToBackend(String accessToken, User user)async{
    // 카카오 로그인 성공 후 사용자 정보를 백엔드 서버로 전송하는 예제
    // 사용자 정보를 백엔드 서버로 전송하기 위해 백엔드 서버의 URL을 입력
    final url = Uri.parse('http://localhost:3000/api/login');

    // 사용자 정보를 백엔드 서버로 전송하기 위해 http 패키지를 사용
    final response = await http.post(
      url,
      headers: <String, String>{// 헤더에 Content-Type을 application/json으로 설정
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{// 사용자 정보를 JSON 형태로 변환하여 body에 입력
        'access_token': accessToken,
        //'user_id': user.id,
        'image_url': user.kakaoAccount?.profile?.profileImageUrl,// 사용자 정보 중 프로필 이미지 URL을 전송
        'profile_nickname': user.kakaoAccount?.profile?.nickname,// 사용자 정보 중 닉네임, 프로필 이미지, 이메일을 전송
        //'profile_email': user.kakaoAccount?.email,
      }),
    );

    if (response.statusCode == 200) {// 백엔드 서버로 사용자 정보 전송 성공 시
      print("User info successfully sent to backend");
    } else {
      print("Failed to send user info to backend: ${response.statusCode}");
    }
  }

  Future<void> addMatch(Map<String, dynamic> matchData) async {
    final url = Uri.parse('http://localhost:3000/api/match');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(matchData),
    );

    if (response.statusCode == 200) {
      print("Match successfully added");
    } else {
      print("Failed to add match: ${response.statusCode}");
    }
  }

  Future<void> getMatch(String id) async {
    final url = Uri.parse('http://localhost:3000/api/match/$id');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      print("Match data: ${response.body}");
    } else {
      print("Failed to fetch match: ${response.statusCode}");
    }
  }

  Future<void> updateMatch(String id, Map<String, dynamic> matchData) async {
    final url = Uri.parse('http://localhost:3000/api/match/$id');

    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(matchData),
    );

    if (response.statusCode == 200) {
      print("Match successfully updated");
    } else {
      print("Failed to update match: ${response.statusCode}");
    }
  }


  Future<void> partialUpdateMatch(String id, Map<String, dynamic> matchData) async {
    final url = Uri.parse('http://localhost:3000/api/match/$id');

    final response = await http.patch(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(matchData),
    );

    if (response.statusCode == 200) {
      print("Match successfully partially updated");
    } else {
      print("Failed to partially update match: ${response.statusCode}");
    }
  }

  Future<void> deleteMatch(String id) async {
    final url = Uri.parse('http://localhost:3000/api/match/$id');

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      print("Match successfully deleted");
    } else {
      print("Failed to delete match: ${response.statusCode}");
    }
  }






  Future<void> signInWithKakao() async {

    // 카카오톡 실행 가능 여부 확인
    // 카카오톡 실행이 가능하면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
        User user = await UserApi.instance.me();
        await sendUserInfoToBackend(token!.accessToken, user);
        Navigator.pushReplacementNamed(context, '/home');

      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        // 이게 안됨!!!! 나중에 고쳐야딩
        try {
          // loginWithKakaoAccount(): 브라우저로 카카오톡을 열어 카카오 계정 입력해 로그인
          token = await UserApi.instance.loginWithKakaoAccount();
          User user = await UserApi.instance.me();
          await sendUserInfoToBackend(token!.accessToken, user);
          Navigator.pushReplacementNamed(context, '/home');
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
        }
      }
    } else {
      try {
        token = await UserApi.instance.loginWithKakaoAccount();
        User user = await UserApi.instance.me();
        print(user.kakaoAccount?.profile?.nickname);
        print(token!.accessToken);
        await sendUserInfoToBackend(token!.accessToken, user);
        Navigator.pushReplacementNamed(context, '/home');
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
          onTap: (){
            signInWithKakao();
          },
          child: Image.asset(
            'assets/kakao_login_large_wide.png',
          )
        )
      )
    );
  }
}


