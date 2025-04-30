import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:micetap_v1/firebase_options.dart';
import 'package:micetap_v1/views/alert_view.dart';
import 'package:micetap_v1/views/config_view.dart';
import 'package:micetap_v1/views/history_view.dart';
import 'package:micetap_v1/views/home_view.dart' show HomeView;
import 'package:micetap_v1/views/register_view.dart';
import 'package:micetap_v1/views/reset_password_view.dart';
import 'package:micetap_v1/views/suggestions_view.dart';
import 'views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

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
