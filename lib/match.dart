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

  factory Match.fromJson(Map<String, dynamic> json){
    return Match(
      matchId: json['match_id'],
      date: json['date'],
      time: json['time'],
      place: json['place'],
      content: json['content'],
      matchTitle: json['match_title'],
      max_member: json['max_member'],
      image: json['image'],
      level: json['level'],
    );
  }
}