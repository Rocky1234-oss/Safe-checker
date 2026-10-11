import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Checker App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ObjectScannerPage(),
    );
  }
}

class ObjectScannerPage extends StatefulWidget {
  const ObjectScannerPage({super.key});

  @override
  State<ObjectScannerPage> createState() => _ObjectScannerPageState();
}

class _ObjectScannerPageState extends State<ObjectScannerPage> {
  File? _imageFile;
  bool _isLoading = false;
  String _resultText = 'Take or pick an image of a product.';

  // Enter your Gemini API Key here
  final String _apiKey = 'YOUR_GEMINI_API_KEY';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _resultText = 'Analyzing...';
      });
      _analyzeImage(_imageFile!);
    }
  }

  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final imageBytes = await image.readAsBytes();
      
      final prompt = TextPart(
        'Identify what object is in this image and mention its estimated market price in Bangladeshi Taka.'
      );
      
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      setState(() {
        _resultText = response.text ?? 'No information found.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultText = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Scanner & Price Checker'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          _resultText,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
