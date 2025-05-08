import 'package:flutter/material.dart';
import 'package:micetap_v1/views/alert_view.dart';
import 'package:micetap_v1/views/config_view.dart';
import 'package:micetap_v1/views/history_view.dart';
import 'package:micetap_v1/views/home_view.dart';
import 'package:micetap_v1/views/login_view.dart';
import 'package:micetap_v1/views/register_view.dart';
import 'package:micetap_v1/views/reset_password_view.dart';
import 'package:micetap_v1/views/suggestions_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/alerts': (context) => AlertsView(),
        '/suggestions': (context) => SuggestionsView(),
        '/config': (context) => ConfigView(),
        '/reset-password': (context) => ResetPasswordView(),
      },
    );
  }
}
