import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakaotest/match.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MatchDetailPage extends StatefulWidget {
  User user;
  final Match match;
  final String currentUserId;

  MatchDetailPage(
      {super.key,
      required this.match,
      required this.currentUserId,
      required this.user});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  String? ip = dotenv.env['ip'];
  double? averageLevel;

  @override
  void initState(){
    super.initState();
    _loadAverageLevel();
  }

  Future<void> _loadAverageLevel() async{
    final level = await fetchAverageLevel((widget.match.matchId).toString());
    setState(() {
      averageLevel = level;
    });
  }

  Future<double?> fetchAverageLevel(String matchId) async{
    final String? baseUrl = dotenv.env['ip'];
    final url = Uri.parse('http://$baseUrl:3000/api/match/$matchId/average-level');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        num averageNum = data['averageLevel'];
        return averageNum.toDouble();
      } else {
        print('Failed to load average level: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching average level: $error');
      return null;
    }
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

  Future<void> deleteMatch(String id) async {
    final url = Uri.parse('http://${ip}:3000/api/match/$id');

    final response = await http.delete(url);

    print(response.body);

    if (response.statusCode == 200) {
      print("Match successfully deleted");
      Navigator.pop(context, widget.match.matchId);
    } else {
      print("Failed to delete match: ${response.statusCode}");
    }
  }

  Future<void> updateMatch(String id, Match match) async {
    final url = Uri.parse('http://${ip}:3000/api/match/$id');

    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(match.toJson()),
    );

    if (response.statusCode == 200) {
      print("Match successfully updated");
    } else {
      print("Failed to update match: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = widget.match.user_id == widget.currentUserId;

    return Scaffold(
      appBar:
          AppBar(backgroundColor: Colors.white, title: Text("경기 상세"), actions: [
        if (isCreator)
          IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () async {
                final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text("삭제 확인"),
                          content: Text("정말 이 게시글을 삭제하시겠습니까?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("취소",
                                  style: TextStyle(color: Colors.black)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text("삭제",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ));
                if (confirmDelete == true) {
                  await deleteMatch(widget.match.matchId.toString());
                }
              })
      ]),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.match.matchTitle}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
          if (widget.match.image != null)
            Center(
                child: Image.network(
              'http://${ip}:3000/${widget.match.image!.replaceFirst(RegExp(r'^/+'), '')}',
              fit: BoxFit.cover,
            )),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${widget.match.cur_member ?? 0}',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              Text(' / ${widget.match.max_member}명',
                  style: TextStyle(fontSize: 12))
            ],
          ),
          SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.stars_outlined, color: Colors.black54),
                      SizedBox(width: 4),
                      Text("평균 ${averageLevel}레벨", style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.black54),
              SizedBox(width: 4),
              Expanded(
                  child: Text('${widget.match.date} ${widget.match.time}',
                      style: TextStyle(fontSize: 15))),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.place_outlined, color: Colors.black54),
              SizedBox(width: 4),
              Expanded(
                  child: Text('${widget.match.place}',
                      style: TextStyle(fontSize: 15))),
            ],
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.chat_outlined, color: Colors.black54),
              SizedBox(width: 4),
              Expanded(
                  child: Text('${widget.match.content}',
                      style: TextStyle(fontSize: 15))),
            ],
          ),
          SizedBox(height: 10),
        ])),
      ),
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: (isUserReserved(widget.match) ||
                (widget.match.cur_member ?? 0) >= widget.match.max_member
            ? null
            : () => reserveMatch(widget.match)),
        label: Text(
          getButtonLabel(widget.match),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: getButtonColor(widget.match),
      ),
    );
  }
}
