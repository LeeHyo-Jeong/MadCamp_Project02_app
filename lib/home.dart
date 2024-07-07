import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakaotest/first_login.dart';
import 'package:kakaotest/match.dart';
import 'package:kakaotest/match_detail.dart';
import 'package:kakaotest/post_match.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Match> matches = []; // 초기 매치 데이터
  List<Match> newMatches = []; // 추가된 매치를 저장할 리스트

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  Future<void> fetchMatches() async {
    List<Match> fetchedMatches=await getAllMatches();
    setState(() {
      matches = fetchedMatches;
    });
  }

  Future<bool> _isFirstLogin(int userId) async{
    final url = Uri.parse('https://localhost:3000/api/is-first-login/$userId');
    final response = await http.get(url);

    if(response.statusCode == 200){
      final result = jsonDecode(response.body);
      return result['isFirstLogin'];
    } else{
      print('Failed to check first login: ${response.statusCode}');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final User user = ModalRoute.of(context)?.settings.arguments as User;

    WidgetsBinding.instance?.addPostFrameCallback((_) async{
      if(await _isFirstLogin(user.id)){
        final result = await showDialog(
          context: context,
          builder: (context) => FirstLoginInfoDialog(accessToken: 'token', user: user),
        );

        if(result == true){
          Fluttertoast.showToast(
            msg: 'First login info submitted',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black54,
            fontSize: 15.0,
            textColor: Colors.white,
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("홈"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<User>(
        future: UserApi.instance.me(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitChasingDots(color: Colors.black38));
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load user info'));
          } else {
            User user = snapshot.data!;
            String? profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
            return Scaffold(
              backgroundColor: Colors.white,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              appBar: AppBar(
                backgroundColor: Colors.white,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    ClipOval(
                      child: profileImageUrl != null
                          ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      )
                          : Image.asset(
                        'assets/football.png',
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text("안녕하세요, ${user.kakaoAccount?.profile?.nickname}님"),
                  ],
                ),
              ),
              body: ListView.builder( // db에서 얻어와서 보여주는 걸로 수정해야 함
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  Match match = matches[index];
                  return Card(
                    color: Colors.white70,
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: ListTile(
                      title: Text(match.matchTitle),
                      subtitle: Text('${match.date} | ${match.time} | ${match.max_member} vs ${match.max_member}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchDetailPage(match: match),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  final newMatch = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PostMatchPage()),
                  );
                  if (newMatch != null) {
                    setState(() {
                      // 경기가 등록되었음을 알린다
                      Fluttertoast.showToast(
                        msg: '새 경기가 등록되었습니다',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.black54,
                        fontSize: 15.0,
                        textColor: Colors.white,
                      );
                    });
                  }
                },
                label: Text("새 경기 등록하기", style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.black,
              ),
            );
          }
        },
      ),
    );
  }
}
