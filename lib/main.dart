// main.dart
import 'package:flutter/material.dart';
import 'package:micetap_v1/views/home_view.dart' show HomeView;
import 'package:micetap_v1/views/register_view.dart';
import 'views/login_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MICETAP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginView(),
        '/register': (context) => RegisterView(),
        
        '/home': (context) => HomeView(),
      },
    );
  }
}