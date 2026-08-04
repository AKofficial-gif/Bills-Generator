import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const BillScannerApp());
}

class BillScannerApp extends StatelessWidget {
  const BillScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Bill Scanner',
      theme: ThemeData(
        // Royal Blue and Gold branding
        primaryColor: const Color(0xFF002366),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF002366),
          secondary: const Color(0xFFFFD700), // Gold
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF002366),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: const Color(0xFF002366),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;

  // Function to pick image from Camera or Gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _extractTextFromImage();
    }
  }

  // Function to run Offline OCR
  Future<void> _extractTextFromImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
      _textController.text = ''; // Clear previous text
    });

    final inputImage = InputImage.fromFile(_image!);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // Dump recognized text into the editable controller
      setState(() {
        _textController.text = recognizedText.text;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recognizing text: $e')),
      );
    } finally {
      textRecognizer.close();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Scanner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image Preview Area
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Center(child: Text('No image selected', style: TextStyle(color: Colors.grey))),
            ),
            const SizedBox(height: 16),
            
            // Camera & Gallery Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Editable Extracted Text Area
            Expanded(
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: 'Extracted bill data will appear here for manual editing...',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
