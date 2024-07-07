import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class FirstLoginInfoDialog extends StatefulWidget {
  final String accessToken;
  final User user;

  const FirstLoginInfoDialog({super.key, required this.accessToken, required this.user});

  @override
  State<FirstLoginInfoDialog> createState() => _FirstLoginInfoDialogState(user: user);
}

class _FirstLoginInfoDialogState extends State<FirstLoginInfoDialog> {
  final User user;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();

  _FirstLoginInfoDialogState({required this.user});

  int? _selectedLevel;
  final List<int> _levelOptions = [1, 2, 3, 4, 5];

  Future<void> _submitForm() async{
    if(_formKey.currentState!.validate()) {
      final level = _levelController.text;
      final team = _teamController.text.isNotEmpty ? _teamController.text : '무소속';

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/user-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}'
        },
        body: jsonEncode({
          'level': level,
          'team': team,
        }),
      );

      if(response.statusCode == 200){
        Navigator.pushReplacementNamed(context, '/home');
      } else{
        print('Failed to save user info');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('정보를 입력하세요'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: '당신의 축구 실력은 어느 정도 인가요?'),
              value: _selectedLevel,
              items: _levelOptions.map((int value){
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (newValue){
                setState(() {
                  _selectedLevel = newValue;
                });
              },
              validator: (value){
                if(value == null){
                  return '축구 실력을 선택 해 주세요';
                }
                return null;
              }
            ),
            TextFormField(
              controller: _teamController,
              decoration: InputDecoration(labelText: "소속 팀 이름을 입력 해 주세요"),
            ),
          ],
        )
      ),
      actions: [
        ElevatedButton(onPressed: _submitForm, child: Text('제출'))
      ],
    );
  }
}
