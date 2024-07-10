import 'dart:convert';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kakaotest/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakaotest/audio_player_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});
  final User user;

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  String? ip = dotenv.env['ip'];

  Future<void> _fetchUserData() async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:3000/api/user/${widget.user.id}'));
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          this.userData = userData;
        });
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  Future<void> _logout() async {
    try {
      await UserApi.instance.logout();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove("kakao_access_token");
      await TokenManagerProvider.instance.manager.clear(); // 모든 토큰 삭제
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (error) {
      print('Logout failed: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void updateUserData(Map<String, dynamic> data) {
    setState(() {
      userData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "프로필",
          style: TextStyle(color: Colors.black, fontFamily: 'Elice'),
        ),
        automaticallyImplyLeading: false,
      ),
      body: userData == null
          ? Center(child: SpinKitChasingDots(color: Colors.black38))
          : SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildProfileHeader(userData!),
            SizedBox(height: 20),
            _buildProfileInfo(userData!),
            SizedBox(height: 20),
            Divider(),
            _buildProfileActions(userData!),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    final profileImageUrl = userData['image_url'];
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipOval(
              child: profileImageUrl != null
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    )
                  : Image.asset(
                      'assets/football.png',
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
            ),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${userData['profile_nickname']}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "한 줄 소개: ${userData['memo']}",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileInfoItem(
                Icons.star, "레벨: ${userData['level'] ?? "레벨 정보가 없습니다"}"),
            Divider(),
            _buildProfileInfoItem(
                Icons.group, "팀: ${userData['team'] ?? "팀 정보가 없습니다"}"),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(IconData icon, String info) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        SizedBox(width: 20),
        Text(
          info,
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActions(Map<String, dynamic> userData) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.edit),
          title: Text('개인 정보 수정'),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditProfilePage(userData: userData)),
            );
            if (result == true) {
              _fetchUserData();
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('알림 설정'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NotificationSettingsPage()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('로그아웃'),
          onTap: _logout,
        ),
      ],
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _memoController = TextEditingController();
  final _levelController = TextEditingController();
  final _teamController = TextEditingController();
  String? ip = dotenv.env['ip'];
  int? _selectedLevel;
  List<int> _levelOptions = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.userData['level'] ?? 0;
    _nicknameController.text = widget.userData['profile_nickname'] ?? '';
    _memoController.text = widget.userData['memo'] ?? '';
    _levelController.text = widget.userData['level']?.toString() ?? '';
    _teamController.text = widget.userData['team'] ?? '';
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.put(
        Uri.parse('http://$ip:3000/api/user/${widget.userData['user_id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile_nickname': _nicknameController.text,
          'memo': _memoController.text,
          'level': int.parse(_levelController.text),
          'team': _teamController.text,
        }),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'Profile updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black54,
          fontSize: 15.0,
          textColor: Colors.white,
        );
        Navigator.pop(context, true);
      } else {
        print('Failed to update profile: ${response.statusCode}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('개인 정보 수정'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(labelText: '닉네임'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력하세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _memoController,
                decoration: InputDecoration(labelText: '메모'),
              ),
              DropdownButtonFormField<int>(
                dropdownColor: Colors.white,
                decoration: InputDecoration(labelText: '레벨',                                filled: true,
                    fillColor: Colors.white),
                value: _selectedLevel,
                items: _levelOptions.map((int value){
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (newValue){
                  setState(() {
                    _selectedLevel = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '레벨을 입력하세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _teamController,
                decoration: InputDecoration(labelText: '팀'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,),
                onPressed: _updateProfile,
                child: Text('수정', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isBgmEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBgmSetting();
  }

  Future<void> _loadBgmSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBgmEnabled = prefs.getBool('isBgmEnabled') ?? true;
    });
  }

  Future<void> _toggleBgm(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBgmEnabled = value;
      prefs.setBool('isBgmEnabled', _isBgmEnabled);
      if (_isBgmEnabled) {
        assetsAudioPlayer.open(
          Audio("assets/audio/Time_Bomb.mp3"),
          loopMode: LoopMode.single,
          autoStart: true,
        );
      } else {
        assetsAudioPlayer.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('배경음 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: Text('배경 음악 켜기/끄기'),
              value: _isBgmEnabled,
              onChanged: _toggleBgm,
            ),
          ],
        ),
      ),
    );
  }
}
