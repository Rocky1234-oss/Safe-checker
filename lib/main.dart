import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

ন
const String myGeminiApiKey = 'Rocky bro';

void main() {
  runApp(const SmartCheckerApp());
}

class SmartCheckerApp extends StatelessWidget {
  const SmartCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false
      title: 'Smart Checker',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ObjectScannerPage(),
    FakeRealVerifierPage(),
    IdentityLookupPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Object Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            label: 'Fake/Real',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search),
            label: 'Identity Lookup',
          ),
        ],
      ),
    );
  }
}

// ---------------- 1ST FEATURE: OBJECT SCANNER ----------------
class ObjectScannerPage extends StatefulWidget {
  const ObjectScannerPage({super.key});

  @override
  State<ObjectScannerPage> createState() => _ObjectScannerPageState();
}

class _ObjectScannerPageState extends State<ObjectScannerPage> {
  File? _imageFile;
  bool _isLoading = false;
  String _resultText = 'Take or pick an image of a product.';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _resultText = 'Analyzing object...';
      });
      _analyzeImage(_imageFile!);
    }
  }

  Future<void> _analyzeImage(File image) async {
    setState(() => _isLoading = true);
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: myGeminiApiKey,
      );
      final imageBytes = await image.readAsBytes();
      final prompt = TextPart('Identify what object is in this image and mention its estimated market price in BDT.');
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
      appBar: AppBar(title: const Text('Object Scanner & Price')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.camera_alt, size: 60)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(_resultText, style: const TextStyle(fontSize: 16)),
              ),
            ),
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
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- 2ND FEATURE: FAKE VS REAL VERIFIER ----------------
class FakeRealVerifierPage extends StatefulWidget {
  const FakeRealVerifierPage({super.key});

  @override
  State<FakeRealVerifierPage> createState() => _FakeRealVerifierPageState();
}

class _FakeRealVerifierPageState extends State<FakeRealVerifierPage> {
  final TextEditingController _inputController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String _verificationResult = 'Enter link, text or upload product image to verify if it is Authentic or Fake.';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _verifyAuthenticity(image: _imageFile);
    }
  }

  Future<void> _verifyAuthenticity({File? image}) async {
    final textContent = _inputController.text.trim();
    if (image == null && textContent.isEmpty) {
      setState(() {
        _verificationResult = 'Please enter a URL/text or select an image first.';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: myGeminiApiKey,
      );

      List<Part> parts = [];
      String promptText = "Analyze this carefully and tell if this is REAL/GENUINE or FAKE/SCAM. "
          "Check for red flags, fake brand signs, scam URLs, or suspicious patterns. Give explanation.";

      if (textContent.isNotEmpty) {
        promptText += " Text/URL to verify: $textContent";
      }

      parts.add(TextPart(promptText));

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        parts.add(DataPart('image/jpeg', imageBytes));
      }

      final response = await model.generateContent([Content.multi(parts)]);

      setState(() {
        _verificationResult = response.text ?? 'Could not verify.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _verificationResult = 'Error verifying: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fake vs Real Verifier')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _inputController,
                decoration: const InputDecoration(
                  labelText: 'Paste Link, Product Details or Text',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_imageFile == null ? 'Attach Image' : 'Image Selected'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyAuthenticity(image: _imageFile),
                      icon: const Icon(Icons.verified),
                      label: const Text('Verify Now'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minHeight: 150),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _verificationResult,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- 3RD FEATURE: IDENTITY LOOKUP ----------------
class IdentityLookupPage extends StatefulWidget {
  const IdentityLookupPage({super.key});

  @override
  State<IdentityLookupPage> createState() => _IdentityLookupPageState();
}

class _IdentityLookupPageState extends State<IdentityLookupPage> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  String _lookupResult = 'Enter Phone Number, FB Profile, or Username to analyze potential risk.';

  Future<void> _analyzeIdentity() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _lookupResult = 'Please enter a number or username.';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: myGeminiApiKey,
      );

      final prompt = "Act as a cybersecurity assistant. Analyze this query: '$query'. "
          "Provide safety tips, risk evaluation (High/Medium/Low), and common scam patterns associated with this type of contact or username format in Bangladesh/worldwide.";

      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        _lookupResult = response.text ?? 'No safety analysis available.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lookupResult = 'Error performing lookup: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity & Scam Lookup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _queryController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number / Username / Profile Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _analyzeIdentity,
                icon: const Icon(Icons.security),
                label: const Text('Check Risk Level'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _lookupResult,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
