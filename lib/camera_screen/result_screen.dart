import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class RecognizerScreen extends StatefulWidget {
  final File image;

  RecognizerScreen({Key? key, required this.image}) : super(key: key);

  @override
  State<RecognizerScreen> createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<RecognizerScreen> {
  late TextRecognizer textRecognizer;

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    doTextRecognition();
  }

  String results = "";

  void doTextRecognition() async {
    InputImage inputImage = InputImage.fromFile(widget.image);
    final RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);

    results = recognizedText.text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recognizer'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(widget.image),
            Card(
              margin: const EdgeInsets.all(10),
              color: Colors.grey.shade300,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey.shade900,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            Icons.document_scanner_outlined,
                            color: Colors.white,
                          ),
                          const Text(
                            "Results",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: results))
                                  .then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Results copied to clipboard!"),
                                  ),
                                );
                              });
                            },
                            child: const Icon(
                              Icons.copy,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:SelectableText(
                      results,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
