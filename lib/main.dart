import 'dart:convert';
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
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
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
  String? ip = dotenv.env['ip'];

  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  final GlobalKey<ReservationPageState> _reservationPageKey = GlobalKey<ReservationPageState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomePage(key: _homePageKey, user: widget.user),
      ReservationPage(key: _reservationPageKey, user: widget.user),
      ProfilePage(user: widget.user)
    ];

    if (widget.isFirstLogin && !_dialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _dialogShown = true;
        final result = await showDialog(
          context: context,
          builder: (context) => FirstLoginInfoDialog(accessToken: 'token', user: widget.user),
        );

        if (result == true) {
          final response = await http.put(
            Uri.parse('http://${ip}:3000/api/user-info'),
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

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('http://$ip:3000/api/user/${widget.user.id}'));
      print("response: ${response.body}");
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _homePageKey.currentState?.updateUserData(userData);
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
        fetchUserDataForReservationPage();
      } else if (index == 0) {
        _homePageKey.currentState?.fetchMatches();
        fetchUserData();
      }
    });
  }
  Future<void> fetchUserDataForReservationPage() async {
    try {
      final response = await http.get(Uri.parse('http://$ip:3000/api/user/${widget.user.id}'));
      print("response: ${response.body}");
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _reservationPageKey.currentState?.updateUserData(userData);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
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
