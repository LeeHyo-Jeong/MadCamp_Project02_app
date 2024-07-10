import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class FirstLoginInfoDialog extends StatefulWidget {
  final String accessToken;
  final User user;

  const FirstLoginInfoDialog(
      {super.key, required this.accessToken, required this.user});

  @override
  State<FirstLoginInfoDialog> createState() =>
      _FirstLoginInfoDialogState(user: user);
}

class _FirstLoginInfoDialogState extends State<FirstLoginInfoDialog> {
  final User user;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  String? ip = dotenv.env['ip'];

  _FirstLoginInfoDialogState({required this.user});

  int? _selectedLevel;
  final List<int> _levelOptions = [1, 2, 3, 4, 5];

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final level = _selectedLevel;
      final team =
          _teamController.text.isNotEmpty ? _teamController.text : '무소속';
      final memo = _memoController.text.isNotEmpty ? _memoController.text : ' ';
      final userId = user.id.toString();

      final response = await http.post(
        Uri.parse('http://${ip}:3000/api/user-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}'
        },
        body: jsonEncode({
          'user_id': userId,
          'memo': memo,
          'level': level,
          'team': team,
        }),
      );
      //print(response.statusCode);
      //print('Response body: ${response}');
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        print('Failed to save user info');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: Text('정보를 입력하세요'),
          content: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                                labelText: '당신의 축구 실력은 어느 정도 인가요?',
                                filled: true,
                                fillColor: Colors.white),
                            value: _selectedLevel,
                            items: _levelOptions.map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedLevel = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return '축구 실력을 선택 해 주세요';
                              }
                              return null;
                            }),
                        TextFormField(
                          controller: _teamController,
                          decoration: InputDecoration(
                              labelText: "소속 팀 이름을 입력 해 주세요",
                              filled: true,
                              fillColor: Colors.white),
                        ),
                        TextFormField(
                          controller: _memoController,
                          decoration: InputDecoration(
                              labelText: "한 줄 소개를 입력 해 주세요",
                              filled: true,
                              fillColor: Colors.white),
                        ),
                      ],
                    ))),
          ),
          actions: [
            ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: Text('제출', style: TextStyle(color: Colors.white)))
          ],
        ));
  }
}
