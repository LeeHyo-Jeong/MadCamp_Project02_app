import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'match.dart';

class PostMatchPage extends StatefulWidget {
  @override
  _PostMatchPageState createState() => _PostMatchPageState();
}

class _PostMatchPageState extends State<PostMatchPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();

  String? _selectedDate;
  String? _selectedTime;
  int? _selectedMemberCount;
  final List<int> _memberOptions = [6, 7, 8, 9, 10, 11, 12];

  // 추후 db에 추가하는 걸로 변경해야 함
  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null && _selectedMemberCount != null) {
      final newMatch = Match(
        matchId: DateTime.now().millisecondsSinceEpoch,
        date: _selectedDate!,
        time: _selectedTime!,
        place: _placeController.text,
        matchTitle: _titleController.text,
        content: _contentController.text,
        max_member: _selectedMemberCount!,
        level: int.parse(_levelController.text),
      );
      Navigator.pop(context, newMatch);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
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
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final selectedDateTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _selectedTime = DateFormat("HH시 mm분").format(selectedDateTime);
        _timeController.text = _selectedTime!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새로운 경기 등록'),
      ),
      body: Card(
        elevation: 30,
        shadowColor: Colors.black,
        color: Color(0xffe6e6e6),
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
                  if(value == null || value.isEmpty){
                    return "내용을 입력 해 주세요";
                  }
                  return null;
                }
              ),
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),),
    );
  }
}
