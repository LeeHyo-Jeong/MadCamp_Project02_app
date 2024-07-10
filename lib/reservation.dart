import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'match.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'match_detail.dart';
import 'package:table_calendar/table_calendar.dart';

String? ip = dotenv.env['ip'];

// 예약한 경기 목록을 가져오는 함수
Future<List<Match>> getUserReservations(String userId) async {
  final url = Uri.parse('http://${ip}:3000/api/user/$userId/reservations');
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
  final url = Uri.parse('http://${ip}:3000/api/match/$matchId/reserve');

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
  final url = Uri.parse('http://${ip}:3000/api/match/$matchId/cancel');

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
  State<ReservationPage> createState() => ReservationPageState();
}

class ReservationPageState extends State<ReservationPage> {
  late Future<List<Match>> futureReservations;
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Match>> _groupedReservations = {};
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  void fetchReservations() {
    setState(() {
      futureReservations = getUserReservations(widget.user.id.toString());
    });
  }

  void updateUserData(Map<String, dynamic> data) {
    setState(() {
      userData = data;
    });
  }

  List<Match> _getEventsForDay(DateTime day) {
    return _groupedReservations[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _groupReservationsByDate(List<Match> reservations) {
    _groupedReservations.clear();
    for (var reservation in reservations) {
      final date = DateFormat('yyyy년 MM월 dd일').parse(reservation.date);
      final formattedDate = DateTime(date.year, date.month, date.day);
      if (_groupedReservations[formattedDate] == null) {
        _groupedReservations[formattedDate] = [];
      }
      _groupedReservations[formattedDate]!.add(reservation);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? profileImageUrl = userData?['image_url'];

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
            Text("${userData?['profile_nickname']}님의 경기", style: TextStyle(fontFamily: 'Elice')),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Match>>(
        future: futureReservations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SpinKitChasingDots(color: Colors.black38));
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load reservations'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No reservations found'));
          } else {
            final reservations = snapshot.data!;
            _groupReservationsByDate(reservations);
            final todayReservations = _getEventsForDay(_selectedDay);
            final otherReservations = reservations
                .where((match) =>
            DateFormat('yyyy년 MM월 dd일').parse(match.date) != _selectedDay)
                .toList();

            return Column(
              children: [
                TableCalendar(
                  calendarStyle: CalendarStyle(selectedDecoration: const BoxDecoration(color: Colors.lightBlue, shape: BoxShape.circle),
                  todayDecoration: const BoxDecoration(color: Colors.lightBlueAccent, shape: BoxShape.circle)),
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _selectedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                    });
                  },
                  eventLoader: _getEventsForDay,
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (todayReservations.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('오늘의 경기',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ...todayReservations.map((reservation) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          margin: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          child: ListTile(
                            title: Text(reservation.matchTitle),
                            subtitle: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${reservation.date} ${reservation.time}',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                    '${reservation.max_member} vs ${reservation.max_member}'),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MatchDetailPage(
                                      match: reservation,
                                      currentUserId: widget.user.id.toString(),
                                      user: widget.user),
                                ),
                              ).then((_) => fetchReservations());
                            },
                            trailing: Column(
                              children: [
                                Text(
                                    '${reservation.cur_member ?? 0} / ${reservation.max_member}'),
                                ConstrainedBox(
                                  constraints: BoxConstraints.tightFor(height: 30),
                                  child: ElevatedButton(
                                  onPressed: () async {
                                    await cancelReservation(
                                        reservation.matchId.toString(),
                                        widget.user.id.toString());
                                    fetchReservations();
                                  },
                                  style: ElevatedButton.styleFrom(

                                    backgroundColor: Colors.red,
                                  ),
                                  child: Text('예약 취소',
                                      style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('전체 경기 목록',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      ...otherReservations.map((reservation) {
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
                                      color: (reservation.cur_member ?? 0) >= reservation.max_member!
                                          ? Colors.red
                                          : (reservation.cur_member ?? 0) > (reservation.max_member! / 2)
                                          ? Colors.orange
                                          : Colors.blue,
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                        title: Text(
                                          reservation.matchTitle,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        subtitle: Container(
                                          color: Colors.grey.shade200,
                                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${reservation.date} ${reservation.time}',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                '${reservation.max_member} vs ${reservation.max_member}',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: SizedBox(
                                          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${reservation.cur_member ?? 0} / ${reservation.max_member}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            SizedBox(height: 5),
                                            Flexible(
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  await cancelReservation(
                                                      reservation.matchId.toString(),
                                                      widget.user.id.toString());
                                                  fetchReservations();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: Text(
                                                  '예약 취소',
                                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],),
                                        ),
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MatchDetailPage(
                                                  match: reservation,
                                                  currentUserId: widget.user.id.toString(),
                                                  user: widget.user),
                                            ),
                                          ).then((_) => fetchReservations());
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
