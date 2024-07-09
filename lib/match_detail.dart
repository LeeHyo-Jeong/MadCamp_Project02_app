import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kakaotest/match.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


class MatchDetailPage extends StatefulWidget {
  final Match match;
  final String currentUserId;

  MatchDetailPage({super.key, required this.match, required this.currentUserId});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {

  String? ip = dotenv.env['ip'];

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

    final isCreator = (widget.match.user_id == widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.match.matchTitle),
        actions: [
          if(isCreator) IconButton(
              icon: Icon(Icons.delete_outline_rounded),
              onPressed: () async{
                final confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text("삭제 확인"),
                    content: Text("정말 이 게시글을 삭제하시겠습니까?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("취소", style: TextStyle(color: Colors.black)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("삭제", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                );
                if(confirmDelete == true){
                  await deleteMatch(widget.match.matchId.toString());
                }
          })
        ]
      )
    );
  }
}