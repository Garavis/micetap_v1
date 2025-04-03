// main.dart
import 'package:flutter/material.dart';
import 'package:micetap_v1/views/alert_view.dart';
import 'package:micetap_v1/views/config_view.dart';
import 'package:micetap_v1/views/history_view.dart';
import 'package:micetap_v1/views/home_view.dart' show HomeView;
import 'package:micetap_v1/views/register_view.dart';
import 'package:micetap_v1/views/suggestions_view.dart';
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
        '/history': (context) => HistoryView(),
        '/alerts': (context) => AlertsView(), // Placeholder for alert view
        '/suggestions': (context) => SuggestionsView(), 
        '/config': (context) => ConfigView(), // Placeholder for config view'
      },
    );
  }
}