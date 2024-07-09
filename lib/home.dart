import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakaotest/match.dart';
import 'package:kakaotest/match_detail.dart';
import 'package:kakaotest/post_match.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomePage extends StatefulWidget {
  final User user;
  final GlobalKey<HomePageState> key;

  const HomePage({required this.user, required this.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Match> matches = [];
  String? ip = dotenv.env['ip'];
  late Future<String> futureNickname;

  @override
  void initState() {
    super.initState();
    futureNickname = fetchUsernickname(widget.user.id.toString());
    fetchMatches();
  }

  Future<String> fetchUsernickname(String userId) async {
    final url = Uri.parse('http://$ip:3000/api/user/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> userdata = jsonDecode(response.body);
      final String nickname = userdata['profile_nickname']; // 서버 응답에서 닉네임 추출
      return nickname;
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> fetchMatches() async {
    List<Match> fetchedMatches = await getAllMatches();
    setState(() {
      matches = fetchedMatches;
    });
  }

  Future<void> reserveMatch(Match match) async {
    if ((match.cur_member ?? 0) >= (match.max_member ?? double.infinity)) {
      Fluttertoast.showToast(
        msg: '이미 예약이 마감 된 경기입니다',
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black54,
        fontSize: 15.0,
        textColor: Colors.white,
      );
      return;
    }

    final url =
        Uri.parse("http://${ip}:3000/api/match/${match.matchId}/reserve");
    final response = await http.post(url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'userId': widget.user.id.toString(),
        }));

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: '예약 되었습니다',
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black54,
        fontSize: 15.0,
        textColor: Colors.white,
      );

      setState(() {
        fetchMatches();
      });
    } else {
      Fluttertoast.showToast(
        msg: '예약에 실패했습니다',
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black54,
        fontSize: 15.0,
        textColor: Colors.white,
      );
    }
  }

  bool isUserReserved(Match match) {
    return match.match_members
        .any((member) => member == widget.user.id.toString());
  }

  String getButtonLabel(Match match) {
    if ((match.cur_member ?? 0) >= match.max_member) {
      return '모집 완료';
    } else if (isUserReserved(match)) {
      return '예약 완료';
    }
    return '예약';
  }

  Color getButtonColor(Match match){
    if((match.cur_member ?? 0) >= match.max_member){
      return Colors.grey;
    } else if (isUserReserved(match)) {
      return Colors.green;
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    User user = widget.user;
    String? profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("홈"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<String>(
        future: futureNickname,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitChasingDots(color: Colors.black38));
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load user info'));
          } else {
            return Scaffold(
              backgroundColor: Colors.white,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
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
                    Text("안녕하세요, ${snapshot.data}님"),
                  ],
                ),
              ),
              body: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  Match match = matches[index];
                  bool userReserved = isUserReserved(match);
                  return Card(
                    color: Colors.white70,
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: ListTile(
                        leading: match.image != null
                            ? SizedBox(
                                width: 50, // 고정된 너비 설정
                                child: Image.network(
                                  'http://${ip}:3000/${match.image!.replaceFirst(RegExp(r'^/+'), '')}',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                        title: Text(match.matchTitle),
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${match.date} ${match.time}',
                                style: TextStyle(
                                  fontSize: 13,
                                )),
                            Text('${match.max_member} vs ${match.max_member}'),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MatchDetailPage(match: match),
                            ),
                          );
                          fetchMatches();
                        },
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${match.cur_member ?? 0} / ${match.max_member}'),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                  onPressed: (userReserved ||
                                          (match.cur_member ?? 0) >=
                                              match.max_member)
                                      ? null
                                      : () => reserveMatch(match),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: getButtonColor(match),
                                  ),
                                  child: Text(getButtonLabel(match),
                                      style: TextStyle(color: Colors.white))),
                            ),
                          ],
                        )),
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
                      Fluttertoast.showToast(
                        msg: '새 경기가 등록되었습니다',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.black54,
                        fontSize: 15.0,
                        textColor: Colors.white,
                      );
                      fetchMatches();
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
