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
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchMatches();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('http://$ip:3000/api/user/${widget.user.id}'));
      print("response: ${response.body}");
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

  void updateUserData(Map<String, dynamic> data) {
    setState(() {
      userData = data;
    });
  }

  Future<void> fetchMatches() async {
    List<Match> fetchedMatches = await getAllMatches();
    matches = fetchedMatches;
    setState(() {
      
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

    print("reserveMatch executed");

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

  Color getButtonColor(Match match) {
    if ((match.cur_member ?? 0) >= match.max_member) {
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
        title: Center(
          child: Image.asset('assets/로고만.jpg', width: 50, height: 50),
        ),
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
                    Text("안녕하세요, ${userData!['profile_nickname']}님", style: TextStyle(fontFamily: 'Elice')),
                  ],
                ),
              ),
              body: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  Match match = matches[index];
                  bool userReserved = isUserReserved(match);
                  return Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 85,  // You can adjust the height based on your needs
                                color: (match.cur_member ?? 0) >= match.max_member!
                                    ? Colors.red
                                    : (match.cur_member ?? 0) > (match.max_member! / 2)
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                  title: Text(
                                    match.matchTitle,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Container(
                                    color: Colors.grey.shade200,
                                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${match.date} ${match.time}',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          '${match.max_member} vs ${match.max_member}',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${match.cur_member ?? 0} / ${match.max_member}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 5),
                                      Flexible(
                                        child: ElevatedButton(
                                          onPressed: (userReserved || (match.cur_member ?? 0) >= match.max_member)
                                              ? null
                                              : () => reserveMatch(match),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: getButtonColor(match),
                                          ).copyWith(
                                            backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                                  (Set<WidgetState> states) {
                                                if (states.contains(WidgetState.disabled)) {
                                                  return getButtonColor(match); // Preserve color when disabled
                                                }
                                                return getButtonColor(match); // Default button color
                                              },
                                            ),
                                          ),
                                          child: Text(
                                            getButtonLabel(match),
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final deletedMatchId = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MatchDetailPage(match: match, currentUserId: user.id.toString(), user: user),
                                      ),
                                    );
                                    fetchMatches();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              floatingActionButton: FloatingActionButton.extended(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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