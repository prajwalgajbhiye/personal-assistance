import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:gemini_chat_bot/pages/chat_page.dart';
import 'package:gemini_chat_bot/pages/welcome_page.dart';
import 'package:gemini_chat_bot/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'consts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Gemini.init(
    apiKey: GEMINI_API_KEY,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstRun = prefs.getBool('firstRun') ?? true;  // Default to true if no value set

  Widget home = isFirstRun ?  WelcomeScreen(onUpdateName: (String ) {  },) :  const HomePage(name: '',);

  if (isFirstRun) {
    // If it's the first run, set it to false for future app launches
    await prefs.setBool('firstRun', false);
  }

  runApp(MyApp(home: home));
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: home);
  }
}
