import 'dart:convert';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakaotest/reservation.dart';
import 'package:kakaotest/home.dart';
import 'package:kakaotest/login.dart';
import 'package:kakaotest/profile.dart';
import 'package:kakaotest/first_login.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:kakaotest/audio_player_service.dart';
import 'package:kakaotest/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  await dotenv.load(fileName: "assets/.env");
  WidgetsFlutterBinding.ensureInitialized();

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
        fontFamily: 'Elice_Regular',
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: SplashScreen(),
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
  String? ip = dotenv.env['ip'];

  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  final GlobalKey<ReservationPageState> _reservationPageKey = GlobalKey<ReservationPageState>();
  final GlobalKey<ProfilePageState> _profilePageKey = GlobalKey<ProfilePageState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomePage(key: _homePageKey, user: widget.user),
      ReservationPage(key: _reservationPageKey, user: widget.user),
      ProfilePage(key: _profilePageKey, user: widget.user),
    ];

    if (widget.isFirstLogin && !_dialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _dialogShown = true;
        final result = await showDialog(
          context: context,
          builder: (context) => FirstLoginInfoDialog(accessToken: 'token', user: widget.user),
        );

        if (result == true) {
          Fluttertoast.showToast(
            msg: '환영합니다!',
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
      });
    }
    _initBgm();
  }
  Future<void> _initBgm() async {
    final prefs = await SharedPreferences.getInstance();
    bool isBgmEnabled = prefs.getBool('isBgmEnabled') ?? true;

    if (isBgmEnabled) {
      assetsAudioPlayer.open(
        Audio("assets/audio/Time_Bomb.mp3"),
        loopMode: LoopMode.single,
        autoStart: true,
      );
    }
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('http://$ip:3000/api/user/${widget.user.id}'));
      print("response: ${response.body}");
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _homePageKey.currentState?.updateUserData(userData);
        _reservationPageKey.currentState?.updateUserData(userData);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  Future<void> fetchUserDataForProfilePage() async {
    try {
      final response = await http.get(Uri.parse('http://$ip:3000/api/user/${widget.user.id}'));
      print("response: ${response.body}");
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _profilePageKey.currentState?.updateUserData(userData);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _reservationPageKey.currentState?.fetchReservations();
        fetchUserData();
      } else if (index == 0) {
        _homePageKey.currentState?.fetchMatches();
        fetchUserData();
      } else if (index == 2) {
        fetchUserDataForProfilePage();
      }
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

// // splash screen 만들기..
//
// class SplashScreen extends StatefulWidget {
//   final User user;
//   final GlobalKey<HomePageState> _homePageKey;
//
//   SplashScreen({required this.user, this.homePageKey});
//
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//
//   @override
//   void initState() {
//     super.initState();
//     _navigateToHome();
//   }
//
//   _navigateToHome() async {
//     await Future.delayed(Duration(seconds: 3), () {}); // 3초 대기
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) =>
//           HomePage(key: widget.homePageKey, user: widget.user)),
//     );
//
//     @override
//     Widget build(BuildContext context) {
//       return MaterialApp(
//         home: LoginPage(),
//         routes: {
//           '/login': (context) => LoginPage(),
//         },
//       );
//     }
//   }
//   }