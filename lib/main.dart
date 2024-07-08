import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakaotest/reservation.dart';
import 'package:kakaotest/home.dart';
import 'package:kakaotest/login.dart';
import 'package:kakaotest/profile.dart';
import 'package:kakaotest/first_login.dart'; // FirstLoginInfoDialog 가져오기
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Fluttertoast 패키지 추가
import 'package:http/http.dart' as http; // http 패키지 추가

void main() async {
  await dotenv.load(fileName: "assets/.env");
  WidgetsFlutterBinding.ensureInitialized();

  // 웹 환경에서 카카오 로그인을 정상적으로 완료하려면 runApp() 호출 전 아래 메서드 호출 필요
  // runApp() 호출 전 Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: dotenv.env['nativeAppKey'],
    javaScriptAppKey: dotenv.env['javaScriptAppKey'],
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kakao Login',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final User user;
  final bool isFirstLogin;

  MyHomePage({required this.user, required this.isFirstLogin});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _dialogShown = false;

  final List<Widget> _pages = [];
  final GlobalKey<HomePageState> _homePageKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _pages.addAll([
      HomePage(key: _homePageKey, user: widget.user),
      ReservationPage(user: widget.user),
      Profilepage()
    ]);

    if (widget.isFirstLogin && !_dialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _dialogShown = true;
        final result = await showDialog(
          context: context,
          builder: (context) => FirstLoginInfoDialog(accessToken: 'token', user: widget.user),
        );

        if (result == true) {
          final response = await http.put(
            Uri.parse('http://localhost:3000/api/user-info'),
            headers: {
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            Fluttertoast.showToast(
              msg: 'First login info submitted',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              fontSize: 15.0,
              textColor: Colors.white,
            );
          } else {
            print('Failed to update isFirstLogin');
          }
        }
      });
    }
  }

  void _onItemTapped(int index){
    if(index == 0){
      _homePageKey.currentState?.fetchMatches();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.shifting,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.history),
            label: '내 경기',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.portrait),
            label: '프로필',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}