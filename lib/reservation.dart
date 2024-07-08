import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'match.dart';
import 'package:http/http.dart' as http;

import 'match_detail.dart';

// 예약한 경기 목록을 가져오는 함수
Future<List<Match>> getUserReservations(String userId) async {
  final url = Uri.parse('http://localhost:3000/api/user/$userId/reservations');
  print("Fetching reservations for user: $userId"); // 디버그 로그 추가
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> reservationsData = jsonDecode(response.body);
    final List<Match> reservations =
    reservationsData.map((data) => Match.fromJson(data)).toList();
    print("Reservations: $reservations");
    return reservations;
  } else {
    throw Exception("Failed to fetch reservations: ${response.statusCode}");
  }
}

Future<void> addReservation(String matchId, String userId) async {
  final url = Uri.parse('http://localhost:3000/api/match/$matchId/reserve');

  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'userId': userId,
    }),
  );

  if (response.statusCode == 200) {
    print("Reservation added successfully");
  } else {
    print("Failed to add reservation: ${response.statusCode}");
  }
}

Future<void> cancelReservation(String matchId, String userId) async {
  final url = Uri.parse('http://localhost:3000/api/match/$matchId/cancel');

  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'userId': userId,
    }),
  );

  if (response.statusCode == 200) {
    print("Reservation cancelled successfully");
  } else {
    print("Failed to cancel reservation: ${response.statusCode}");
  }
}

class ReservationPage extends StatefulWidget {
  final User user;
  const ReservationPage({super.key, required this.user});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  late User user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    //fetchmatches();
  }

  @override
  Widget build(BuildContext context) {
    String? profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
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
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Match>>(
        future: getUserReservations(user.id.toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitChasingDots(color: Colors.black38));
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load reservations'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No reservations found'));
          } else {
            final reservations = snapshot.data!;
            return ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                //final dateTime = DateFormat('yyyy-MM-dd HH:mm').parse('${reservation.date} ${reservation.time}');
                //final formattedDateTime =
                //DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
                return Card(
                  color: Colors.white70,
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: ListTile(
                    title: Text(reservation.matchTitle),
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${reservation.date} ${reservation.time}', style: TextStyle(fontSize: 13,)),
                        Text('${reservation.max_member} vs ${reservation.max_member}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchDetailPage(match: reservation),
                        ),
                      );
                      //fetchMatches();

                    },
                    trailing: Column(
                        children: [
                    Text('${reservation.cur_member ?? 0} / ${reservation.max_member}'),
                    ElevatedButton(
                      onPressed: () async {
                        await cancelReservation(
                            reservation.matchId.toString(), user.id.toString());
                        setState(() {
                          reservations.removeAt(index);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,

                      ),
                      child: Text('예약 취소', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  ),
                )
                );
              },
            );
          }
        },
      ),
    );
  }
}