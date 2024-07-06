import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: FutureBuilder<User>(
        future: UserApi.instance.me(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          } else if(snapshot.hasError){
            return Center(child: Text('Failed to load user info'));
          } else{
            User user = snapshot.data!;
            return Center(
              child: Row(
                children: [
                  Image.network(user.kakaoAccount?.profile?.profileImageUrl ?? ' '),
                  Text("Hello, ${user.kakaoAccount?.profile?.nickname}"),
                ],
              )
            );
          }
        }
      )
    );
  }
}
