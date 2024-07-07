import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakaotest/reservation.dart';
import 'package:kakaotest/home.dart';
import 'package:kakaotest/login.dart';
import 'package:kakaotest/profilePage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: MyHomePage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => MyHomePage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    ReservationPage(),
    Profilepage(),
  ];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    OAuthToken? token = await TokenManagerProvider.instance.manager.getToken();

    if (token != null) {
      try {
        User user = await UserApi.instance.me();
        setState(() {
          _isLoggedIn = true;
        });
      } catch (e) {
        print("Failed to load user info with stored token: $e");
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Scaffold(
        body: Center(
          child: SpinKitChasingDots(color: Colors.black38),
        ),
      );
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedIconTheme: IconThemeData(color: Colors.black),
        unselectedIconTheme: IconThemeData(color: Colors.grey),
        type: BottomNavigationBarType.shifting,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: '내 예약',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: '프로필',
            backgroundColor: Colors.white,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold
        ),
        unselectedItemColor: Colors.black54,
        onTap: _onItemTapped,
      ),
    );
  }
}
