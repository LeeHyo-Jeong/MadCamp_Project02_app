import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class Match {
  final int matchId;
  final String date;
  final String time;
  final String place;
  final String matchTitle;
  final String content;
  final int max_member;
  final String? image;
  final int level;
  int? cur_member;
  List<String> match_members; //user_id의 list

  Match({
    required this.matchId,
    required this.date,
    required this.time,
    required this.place,
    required this.matchTitle,
    required this.content,
    required this.max_member,
    this.image,
    required this.level,
    this.cur_member,
    required this.match_members,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    print('$json');
    var userList = json['match_members'] as List;
    List<String> match_members = userList.map((i) => i.toString()).toList();
    print(match_members);

    return Match(
      matchId: json['matchId'],
      date: json['date'],
      time: json['time'],
      place: json['place'],
      content: json['content'],
      matchTitle: json['matchTitle'],
      max_member: json['max_member'],
      image: json['image'],
      level: json['level'],
      cur_member: json['cur_member'],
      match_members: match_members,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'date': date,
      'time': time,
      'place': place,
      'matchTitle': matchTitle,
      'content': content,
      'max_member': max_member,
      'image': image,
      'level': level,
      'cur_member': cur_member,
      'match_members': match_members,
    };
  }
}
