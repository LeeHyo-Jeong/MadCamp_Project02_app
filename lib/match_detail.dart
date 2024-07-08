import 'package:flutter/material.dart';
import 'package:kakaotest/match.dart';
import 'home.dart';

class MatchDetailPage extends StatefulWidget {
  final Match match;
  const MatchDetailPage({super.key, required this.match});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}