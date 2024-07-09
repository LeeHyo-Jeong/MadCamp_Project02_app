import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'match.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

String? ip = dotenv.env['ip'];

Future<User> getUser() async{
  try {
    User user = await UserApi.instance.me();
    return user;
  } catch(e){
    print("Error getting user ${e}");
    throw e;
  }
}

Future<void> addMatch(Match match) async {
  final url = Uri.parse('http://${ip}:3000/api/match');

  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(match.toJson()),
  );

  if (response.statusCode == 200) {
    print("Match successfully added");
  } else {
    print("Failed to add match: ${response.statusCode}");
  }
}

Future<Match> getMatch(String id) async {
  final url = Uri.parse('http://${ip}:3000/api/match/$id');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final Map<String, dynamic> matchData = jsonDecode(response.body);
    final match = Match.fromJson(matchData);
    return match;
  } else {
    throw Exception("Failed to fetch match: ${response.statusCode}");
  }
}

Future<List<Match>> getAllMatches() async {
  final url = Uri.parse('http://${ip}:3000/api/match');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> matchesData = jsonDecode(response.body);
    final List<Match> matches =
        matchesData.map((data) => Match.fromJson(data)).toList();
    //print("Matches data: ${matches.map((match) => match.toJson())}");
    return matches;
  } else {
    throw Exception("Failed to fetch matches: ${response.statusCode}");
  }
}

class PostMatchPage extends StatefulWidget {
  @override
  _PostMatchPageState createState() => _PostMatchPageState();
}

class _PostMatchPageState extends State<PostMatchPage> {

  User? user;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  File? _image;

  String? _selectedDate;
  String? _selectedTime;
  int? _selectedMemberCount;
  final List<int> _memberOptions = [6, 7, 8, 9, 10, 11, 12];

  Future<void> _initializeUser() async{
    try{
      User user = await getUser();
      setState(() {
        this.user = user;
      });
    } catch(e){
      print("Error initializing user ${e}");
    }
  }

  @override
  void initState(){
    super.initState();
    _initializeUser();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    final uri = Uri.parse('http://${ip}:3000/api/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      print("Image data: ${data}");

      return data['image'];
    } else {
      print("Image upload failed with status ${response.statusCode}");
      return null;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedMemberCount != null) {
      String? imageUrl;

      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      final newMatch = Match(
        matchId: DateTime.now().millisecondsSinceEpoch,
        date: _selectedDate!,
        time: _selectedTime!,
        place: _placeController.text,
        matchTitle: _titleController.text,
        content: _contentController.text,
        max_member: _selectedMemberCount!,
        level: int.parse(_levelController.text),
        match_members: [],
        image: imageUrl,
        user_id: user!.id.toString()
      );
      addMatch(newMatch);
      Navigator.pop(context, newMatch);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child){
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.white70,
            colorScheme: ColorScheme.light(primary: Colors.black),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat("yyyy년 MM월 dd일").format(picked);
        _dateController.text = _selectedDate!;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child){
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.white70,
            colorScheme: ColorScheme.light(primary: Colors.black),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final selectedDateTime =
            DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _selectedTime = DateFormat("HH시 mm분").format(selectedDateTime);
        _timeController.text = _selectedTime!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('새로운 경기 등록'),
      ),
      body: Card(
        //elevation: 30,
        shadowColor: Colors.black,
        color: Color(0xfff5f5f5),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: '제목'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '모집글 제목을 입력 해 주세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _placeController,
                  decoration: InputDecoration(labelText: '경기 장소'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '경기 장소를 입력 해 주세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: '경기 날짜',
                    hintText: 'yyyy년 MM월 dd일',
                  ),
                  onTap: () {
                    FocusScope.of(context).requestFocus(new FocusNode());
                    _selectDate(context);
                  },
                  validator: (value) {
                    if (_selectedDate == null) {
                      return '경기 날짜를 선택 해 주세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: '경기 시간',
                    hintText: 'HH시 mm분',
                  ),
                  onTap: () {
                    FocusScope.of(context).requestFocus(new FocusNode());
                    _selectTime(context);
                  },
                  validator: (value) {
                    if (_selectedTime == null) {
                      return '경기 시간을 선택 해 주세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(labelText: "내용"),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "내용을 입력 해 주세요";
                      }
                      return null;
                    }),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: '팀 인원 수'),
                  value: _selectedMemberCount,
                  items: _memberOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedMemberCount = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return '팀의 인원 수를 입력 해 주세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _levelController,
                  decoration: InputDecoration(labelText: '축구 실력'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '축구 실력을 입력 해 주세요';
                    }
                    if (int.tryParse(value) == null) {
                      return '실력은 1~10 사이의 수로 입력 해 주세요';
                    }
                    return null;
                  },
                ),
                _image != null ? Image.file(_image!) : Container(),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  onPressed: _pickImage,
                  child: Text("이미지 선택", style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  onPressed: _submitForm,
                  child: Text('등록',
                      style: TextStyle(
                        color: Colors.white,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
