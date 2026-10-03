import 'package:flutter/material.dart';
import 'package:animeverse/screens/detail_screen.dart';
import 'package:animeverse/screens/favorite_screen.dart';
import 'package:animeverse/screens/home_screen.dart';
import 'package:animeverse/screens/profile_screen.dart';
import 'package:animeverse/screens/signin_screen.dart';
import 'package:animeverse/screens/signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Verse',
      theme: ThemeData(
        fontFamily: 'Urbanist',
      ),
      home: const SignInScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}