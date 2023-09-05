import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  String extractedText = "";
  final FlutterTts flutterTts = FlutterTts();

  Future<void> _getImageAndExtractText(ImageSource source) async {
    final XFile? pickedImage = await _picker.pickImage(source: source);

    if (pickedImage == null) return;

    final InputImage inputImage = InputImage.fromFilePath(pickedImage.path);

    final TextRecognizer textRecognizer = GoogleMlKit.vision.textRecognizer();

    final RecognizedText recognisedText =
        await textRecognizer.processImage(inputImage);

    String extractedText = recognisedText.text;

    setState(() {
      this.extractedText = extractedText;
    });

    _speakText(extractedText);
  }

  Future<void> _speakText(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.setLanguage('en-US'); // Set the desired language
      await flutterTts.speak(text); // Speak the extracted text
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Extractor App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(),
              ),
              child: extractedText.isNotEmpty
                  ? SingleChildScrollView(
                      child: Text(
                        extractedText,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    )
                  : Center(
                      child: Text('No Text Extracted'),
                    ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => _getImageAndExtractText(ImageSource.camera),
                  child: Text('Pick Image from Camera'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _getImageAndExtractText(ImageSource.gallery),
                  child: Text('Pick Image from Gallery'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _speakText(extractedText),
              child: Text('Speak Text'),
            ),
          ],
        ),
      ),
    );
  }
}


//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