class Match{
  final int matchId;
  final String date;
  final String time;
  final String place;
  final String matchTitle;
  final String content;
  final int max_member; // 한 팀에 몇명인지?
  final String? image;
  final int level;
  final int? cur_member;

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
  });

  factory Match.fromJson(Map<String, dynamic> json){// JSON 형태의 데이터를 Match 객체로 변환
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
    };
  }
}