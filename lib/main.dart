import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String generatedSentence = "";
  bool isLoading = false; // Added to track API request status
  final FlutterTts flutterTts = FlutterTts();

  Future<void> _getImageAndExtractText(ImageSource source) async {
    setState(() {
      isLoading = true; // Start loading indicator
    });

    final XFile? pickedImage = await _picker.pickImage(source: source);

    if (pickedImage == null) {
      setState(() {
        isLoading = false; // Stop loading indicator
      });
      return;
    }

    final InputImage inputImage = InputImage.fromFilePath(pickedImage.path);

    final TextRecognizer textRecognizer = GoogleMlKit.vision.textRecognizer();

    final RecognizedText recognisedText =
        await textRecognizer.processImage(inputImage);

    String extractedText = recognisedText.text;

    setState(() {
      this.extractedText = extractedText;
      this.generatedSentence = "";
    });

    try {
      final generatedSentence = await sendToOpenAI(extractedText);
      _speakText(generatedSentence);
    } catch (e) {
      print('Error sending data to OpenAI: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading indicator
      });
    }
  }

  Future<void> _speakText(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.setLanguage('en-US');
      await flutterTts.speak(text);
    }
  }

  Future<String> sendToOpenAI(String text) async {
    final apiKey = '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';
    final openaiEndpoint =
        'https://api.openai.com/v1/engines/text-davinci-002/completions';

    try {
      final response = await http.post(
        Uri.parse(openaiEndpoint),
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt':
              'Convert the following text to easily understandable sentences:\n$text',
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedSentence = data['choices'][0]['text'];

        setState(() {
          this.generatedSentence = generatedSentence;
        });

        return generatedSentence;
      } else {
        print('OpenAI API Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to connect to the OpenAI API');
      }
    } catch (e) {
      print('Error sending data to OpenAI: $e');
      throw e;
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
            isLoading // Check if API request is in progress
                ? CircularProgressIndicator() // Show loading indicator
                : Text(
                    generatedSentence.isNotEmpty
                        ? 'Generated Sentence:\n$generatedSentence'
                        : 'No Generated Sentence',
                    style: TextStyle(fontSize: 16.0),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _speakText(generatedSentence),
              child: Text('Speak Generated Sentence'),
            ),
          ],
        ),
      ),
    );
  }
}
