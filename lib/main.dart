import 'package:E_HandyHelp/FirstPage.dart';
import 'package:E_HandyHelp/HandyMan/HandyManHomePage.dart';
import 'package:E_HandyHelp/HandyMan/HandyManRegister.dart';
import 'package:E_HandyHelp/User/UserHomePage.dart';
import 'package:E_HandyHelp/User/ServiceRequest.dart';
import 'package:flutter/material.dart';




void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: 'E-HandyHelp',
        debugShowCheckedModeBanner: false,
        home: FirstPage());

  }
}
