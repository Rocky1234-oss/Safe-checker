import 'dartt:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Ekhane apnar Gemini API Key-ti boshaben
const String myGeminiApiKey = 'Rocky bro';

void main() {
  runApp(const SmartCheckerApp());
}

class SmartCheckerApp extends StatelessWidget {
  const SmartCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
    final XFile? pickedFile = await _picker.pickImage(source
