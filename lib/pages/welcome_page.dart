import 'package:flutter/material.dart';
import 'package:gemini_chat_bot/custom_class.dart';
import 'package:gemini_chat_bot/pages/home_page.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String userName = "";

  void updateUserName(String newName) {
    setState(() {
      userName = newName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot Setup',
      home: WelcomeScreen(
        name: userName,
        onUpdateName: updateUserName,
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  final String name;
  final Function(String) onUpdateName;

  const WelcomeScreen({super.key, this.name = "", required this.onUpdateName});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _isNameSaved =
      false; // State to control the activation of the "Let's Go" button
  bool _isEditing = false;

  IconData _lockIcon = Icons.lock_open;
  List<Color> _currentColors = [Colors.red.shade900, Colors.grey];
  List<Alignment> _currentAlignments = [
    Alignment.bottomLeft,
    Alignment.topRight
  ];

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadName();
    _controller.addListener(_updateSaveButtonState);
    _controller.addListener(_onTextChanged);
    _controller.text = widget.name;
    _isNameSaved = _controller.text.isNotEmpty;
    _isEditing = false;

    _controller.addListener(() {
      setState(() {
        _lockIcon = _controller.text.isEmpty ? Icons.lock_open : Icons.lock;
      });
    });
    _startColorChange();
  }

  void _onTextChanged() {
    // Always check the current text against the saved name
    bool currentTextIsSavedName = _controller.text == widget.name;
    if (currentTextIsSavedName) {
      if (_isEditing) {
        setState(() {
          _isEditing = false;
          _isNameSaved = true; // Enable "Let's Go" if text matches saved name
        });
      }
    } else {
      if (!_isEditing) {
        setState(() {
          _isEditing = true;
          _isNameSaved = false; // Disable "Let's Go" button
        });
      }
    }
  }

  void _loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('name');
    if (savedName != null) {
      _controller.text = savedName;
      setState(() {
        _isNameSaved = true;
      });
    }
  }

  void showCustomSnackBar(
      BuildContext context, String text, List<Color> colors, Color textColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Container(
        height: 40,
        width: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        ),
      ),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 80, left: 100, right: 100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.transparent,
    ));
  }

  void _updateSaveButtonState() {
    if (_controller.text.isEmpty) {
      setState(() {
        _isNameSaved = false; // Ensures button is disabled when field is empty
        _lockIcon = _controller.text.isEmpty ? Icons.lock_open : Icons.lock;
      });
    }
  }

  void _saveName() async {
    if (_controller.text.isEmpty) {
      showCustomSnackBar(context, "Please Enter Name",
          [Colors.yellowAccent, Colors.white], Colors.black);
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _controller.text);
      widget.onUpdateName(
          _controller.text); // Update the name in the parent state
      showCustomSnackBar(context, 'Name saved: ${_controller.text}',
          [Colors.white, Colors.pinkAccent], Colors.grey.shade900);

      setState(() {
        _isNameSaved = true;
        _isEditing = false; // No longer editing
      });
    }
  }

  void _onPressed() {
    if (_isNameSaved) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(
                    name: _controller.text,
                  )));
    }
  }

  void _startColorChange() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentColors = _currentColors[0] == Colors.redAccent.shade400
            ? [Colors.pink, Colors.orange]
            : [Colors.redAccent.shade400, Colors.white];
        _currentAlignments = _currentAlignments[0] == Alignment.bottomLeft
            ? [Alignment.topRight, Alignment.bottomLeft]
            : [Alignment.bottomLeft, Alignment.topRight];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showCustomSnackBar(context, 'Enter a name ',
            [Colors.white, Colors.black], Colors.black);

        return false;
      },
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(seconds: 5),
          onEnd: () => setState(() {}),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _currentAlignments[0],
              end: _currentAlignments[1],
              colors: _currentColors,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Row(
                  children: [
                    SizedBox(
                      width: 55,
                    ),
                    Text('Welcome',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Enter Your Name",
                      // labelText: 'Enter your name',
                      labelStyle: const TextStyle(color: Colors.black54),
                      suffixIcon: Icon(_lockIcon, color: Colors.black),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: _isEditing ? Colors.red : Colors.blue),
                      ),
                      filled: true,
                      // This must be set to true to use fillColor
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _saveName,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: _isNameSaved
                            ? const LinearGradient(
                                colors: [Colors.blue, Colors.purple],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : const LinearGradient(
                                colors: [Colors.grey, Colors.grey],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        borderRadius:
                            BorderRadius.circular(30), // Rounded corners
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _isNameSaved ? null : Colors.grey,
                          // Ignore backgroundColor when gradient is visible
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 10),
                          // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _isNameSaved ? _onPressed : null,
                        // Disable button when name isn't saved
                        child: const Text(
                          "Let's Go",
                          style: TextStyle(
                              color: Colors
                                  .white), // Ensure text is always white for better visibility
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }
}
