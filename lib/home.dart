import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakaotest/match.dart';
import 'package:intl/intl.dart';
import 'package:kakaotest/match_detail.dart';
import 'package:kakaotest/post_match.dart';

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
    // 현재는 더미 데이터로 부터 경기 정보를 얻어와서 저장하도록 함
    // 나중에 db로부터 데이터 받아오는 걸로 변경해야 함
    List<Match> dummyMatches = [
      Match(
        matchId: 1,
        date: DateFormat("yyyy년 MM월 dd일").format(DateTime(2024, 7, 6)),
        time: DateFormat("HH시 mm분").format(DateTime(2024, 7, 6, 22, 0)),
        place: "대전 유성구 유성대로713번길 83",
        matchTitle: "대전 유성 풋살구장 1구장",
        content: "같이 축구해요",
        max_member: 11,
        level: 5,
      ),
      Match(
        matchId: 2,
        date: DateFormat("yyyy년 MM월 dd일").format(DateTime(2024, 7, 8)),
        time: DateFormat("HH시 mm분").format(DateTime(2024, 7, 8, 17, 30)),
        place: "경기 고양시 일산동구 중앙로1275번길 64",
        matchTitle: "고양 HM풋살파크 일산점 B구장",
        content: "같이 축구해요",
        max_member: 6,
        level: 3,
      ),
      Match(
        matchId: 3,
        date: DateFormat("yyyy년 MM월 dd일").format(DateTime(2024, 7, 6)),
        time: DateFormat("HH시 mm분").format(DateTime(2024, 7, 6, 20, 30)),
        place: "서울 송파구 성내천로29길 31",
        matchTitle: "서울 송파 천마 풋살파크 4구장",
        content: "같이 축구해요",
        max_member: 6,
        level: 5,
      ),
      Match(
        matchId: 4,
        date: DateFormat("yyyy년 MM월 dd일").format(DateTime(2024, 7, 6)),
        time: DateFormat("HH시 mm분").format(DateTime(2024, 7, 6, 20, 0)),
        place: "경기 성남시 수정구 사송로 77번길 31",
        matchTitle: "성남 분당 킹주니어 스포츠 클럽",
        content: "같이 축구해요",
        max_member: 8,
        level: 1,
      ),
      Match(
        matchId: 5,
        date: DateFormat("yyyy년 MM월 dd일").format(DateTime(2024, 7, 6)),
        time: DateFormat("HH시 mm분").format(DateTime(2024, 7, 6, 22, 0)),
        place: "집에가고싶다 경기도 광주시 경충대로 1422번길 42",
        matchTitle: "준형아언제와...",
        content: "~~~~~집가고시풔~~~~",
        max_member: 6,
        level: 2,
      ),
      Match(
        matchId: 6,
        date: DateFormat("yyyy년 MM월 dd일").format(DateTime(2024, 7, 6)),
        time: DateFormat("HH시 mm분").format(DateTime(2024, 7, 6, 22, 0)),
        place: "집에가고싶다 경기도 광주시 경충대로 1422번길 42",
        matchTitle: "고수만 오셈",
        content: "같이 축구해요",
        max_member: 6,
        level: 2,
      ),
    ];

    setState(() {
      matches = dummyMatches;
    });
  }

  void _addMatch(Match match) {
    setState(() {
      matches.add(match);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<User>(
        future: UserApi.instance.me(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load user info'));
          } else {
            User user = snapshot.data!;
            String? profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
            return Scaffold(
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              appBar: AppBar(
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
              body: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  Match match = matches[index];
                  return Card(
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
                    _addMatch(newMatch);
                  }
                },
                label: Text("팀원 모집하기", style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.black,
              ),
            );
          }
        },
      ),
    );
  }
}
