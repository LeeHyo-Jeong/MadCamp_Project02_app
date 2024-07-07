import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("프로필"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<User>(
        future: UserApi.instance.me(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: SpinKitChasingDots(color: Colors.black38));
          } else if(snapshot.hasError){
            return Center(child: Text('Failed to load user info'));
          } else{
            User user = snapshot.data!;
            String? profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
            return Center(
              child: Column(
                children: [
                  ClipOval(
                    child: profileImageUrl != null
                        ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    )
                        : Image.asset(
                      'assets/football.png',
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("${user.kakaoAccount?.profile?.nickname}",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ],
              ),
            );
          }
        }
      )
    );
  }
}
