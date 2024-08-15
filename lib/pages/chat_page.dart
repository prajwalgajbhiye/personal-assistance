import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:gemini_chat_bot/camera_screen/camera_screen.dart';
import 'package:gemini_chat_bot/pages/welcome_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(
        name: '',
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String name;

  const HomePage({super.key, required this.name});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";

  final Gemini gemini = Gemini.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  DateTime? lastTimeBackButtonWasPressed;

  List<ChatMessage> messages = [];
  bool isTyping = false;

  late ChatUser currentUser = ChatUser(id: "0", firstName: widget.name);
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage: "images/cuteimg.png",
  );

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => _showMenu(context),
            icon: const Icon(Icons.menu),
          ),
          centerTitle: true,
          title: const Text("Gemini Chat"),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.white],
          )),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0 && isTyping) {
                      return _buildTypingIndicator();
                    }
                    final message = messages[index - (isTyping ? 1 : 0)];
                    bool isCurrentUser = message.user.id == currentUser.id;

                    return GestureDetector(
                      onDoubleTap: () {
                        Clipboard.setData(ClipboardData(text: message.text))
                            .then((_) => ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Container(
                                    height: 40,
                                    width: 70,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade900,
                                          Colors.white
                                        ],
                                        // Customize gradient colors here
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          20), // Curved edges
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 10),
                                    child: const Text(
                                      "Text copied",
                                      style: TextStyle(
                                        color: Colors.white, // Text color
                                        fontSize: 16, // Text size
                                      ),
                                    ),
                                  ),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  padding: const EdgeInsets.all(0),
                                  // Remove default padding inside SnackBar
                                  margin: const EdgeInsets.only(
                                      bottom: 80, left: 100, right: 100),
                                  // Adjust margins to position SnackBar
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        20), // Match Container's border radius
                                  ),
                                  backgroundColor: Colors
                                      .transparent, // Ensure SnackBar background is transparent
                                )));
                      },
                      child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(
                                message.user.profileImage ??
                                    'images/no-dp.jpg'),
                          ),
                          title: Text(
                            message.user.firstName,
                            style: TextStyle(
                                color: isCurrentUser
                                    ? Colors.white
                                    : Colors.white),
                          ),
                          subtitle: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isCurrentUser
                                    ? Colors.grey[900]
                                    : Colors.black,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: SelectableText(
                                message.text,
                                style: TextStyle(
                                    fontWeight: isCurrentUser
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.white),
                              )),
                          trailing: Icon(
                            isCurrentUser
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color: isCurrentUser ? Colors.white : Colors.white,
                          )),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: _sendMediaMessage,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: "Type a message...",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          _handleSendMessage(_messageController.text);
                          _messageController.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Offset.zero & const Size(40, 40), // smaller rect, the touch area
        Offset.zero & overlay.size, // Bigger rect, the entire screen
      ),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          value: 'Name',
          child: const Text('Name'),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        WelcomeScreen(onUpdateName: (String name) {
                          // This might just log the name or do nothing if not needed
                          print("Name updated to: $name");
                        })));
          },
        ),
        PopupMenuItem(
          value: 'Recognition',
          child: const Text('Recognition'),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HomeScreen2()));
          },
        ),
      ],
    ).then((value) {
      // Handle the action based on the selected value
      if (value == 'camera') {
        // Open camera
      } else if (value == 'gallery') {
        // Open gallery
      }
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (lastTimeBackButtonWasPressed == null ||
        now.difference(lastTimeBackButtonWasPressed!) >
            const Duration(seconds: 2)) {
      // Update the last time back button was pressed
      lastTimeBackButtonWasPressed = now;

      // Show the SnackBar
      final snackBar = SnackBar(
        content: Container(
          height: 40,
          width: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: const Text(
            "Press back again to exit",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.all(0),
        margin: const EdgeInsets.only(bottom: 40, left: 50, right: 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.transparent,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false; // Do not exit the app
    } else {
      return true; // Exit the app
    }
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          SizedBox(width: 5),
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
          SizedBox(width: 15),
          Text("Gemini is typing...", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  void _handleSendMessage(String text) {
    if (text.isNotEmpty) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: text,
      );
      _sendMessage(chatMessage);
    }
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages.insert(0, chatMessage);
      isTyping = true;
    });

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    List<String> responseParts = []; // List to hold parts of the response
    String fullResponse =
        ""; // This will hold the gradually built full response

    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }

      var subscription = gemini
          .streamGenerateContent(
        question,
        images: images,
      )
          .listen((event) {
        // Collect each part of the response
        String part = event.content?.parts?.map((e) => e.text).join(" ") ?? "";
        if (part.isNotEmpty) {
          responseParts.add(part);
          // Append the new part to the full response
          fullResponse += "$part ";

          // Update the existing 'typing' message with the new full response
          if (messages.isNotEmpty && messages[0].user.id == geminiUser.id) {
            // Update the existing message text
            messages[0] = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: fullResponse,
            );
          } else {
            // Create a new message if it's the first part
            messages.insert(
                0,
                ChatMessage(
                  user: geminiUser,
                  createdAt: DateTime.now(),
                  text: fullResponse,
                ));
          }

          setState(() {});
        }
      }, onError: (error) {
        print("Error receiving data from Gemini: $error");
        setState(() {
          isTyping = false;
        });
      });

      subscription.onDone(() {
        // Final update when the response is fully received
        setState(() {
          isTyping = false;
        });
      });
    } catch (e) {
      print("Exception caught: $e");
      setState(() {
        isTyping = false;
      });
    }
  }

  void _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('name');
    if (savedName != null) {
      setState(() {
        userName = savedName;
        currentUser = ChatUser(
            id: "0",
            firstName: savedName); // Update currentUser with the loaded name
      });
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}

// Placeholder classes to mimic required classes
class ChatUser {
  final String id;
  final String firstName;
  final String? profileImage;

  ChatUser({required this.id, required this.firstName, this.profileImage});
}

class ChatMessage {
  final ChatUser user;
  final DateTime createdAt;
  final String text;
  final List<ChatMedia>? medias;

  ChatMessage(
      {required this.user,
      required this.createdAt,
      required this.text,
      this.medias});
}

class ChatMedia {
  final String url;
  final String fileName;
  final MediaType type;

  ChatMedia({required this.url, required this.fileName, required this.type});
}

enum MediaType { image, video }
