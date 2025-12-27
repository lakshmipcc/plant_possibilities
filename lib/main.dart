import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'gemini_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  runApp(const PlantPossApp());
}

class PlantInfo {
  final String commonName;
  final String scientificName;
  final String funFact;

  PlantInfo({
    required this.commonName,
    required this.scientificName,
    required this.funFact,
  });

  factory PlantInfo.fromJson(Map<String, dynamic> json) {
    return PlantInfo(
      commonName: json['commonName'] ?? 'Unknown',
      scientificName: json['scientificName'] ?? 'Unknown',
      funFact: json['funFact'] ?? 'No fun fact available.',
    );
  }
}

class PlantPossApp extends StatelessWidget {
  const PlantPossApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color sageGreen = Color(0xFF8A9A5B);
    const Color terracotta = Color(0xFFC04000);
    const Color cream = Color(0xFFF5F5DC);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Possibilities',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: sageGreen,
          primary: sageGreen,
          secondary: terracotta,
          surface: cream,
        ),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: sageGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: terracotta,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GeminiService _geminiService = GeminiService();
  Uint8List? _selectedFileBytes;
  PlantInfo? _plantInfo;
  bool _isLoading = false;

  Future<void> _pickAndIdentifyImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      final bytes = result.files.single.bytes;
      final name = result.files.single.name;
      if (bytes != null) {
        setState(() {
          _selectedFileBytes = bytes;
          _plantInfo = null;
          _isLoading = true;
        });

        try {
          final data = await _geminiService.identifyPlant(bytes, name);
          setState(() {
            _plantInfo = PlantInfo.fromJson(data);
          });
        } catch (e) {
          if (mounted) {
            String message = e.toString();
            if (message.contains('AssetManifest')) {
              message = 'Please create assets/plants/plants_data.json to use offline mode.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
            );
          }
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Possibilities'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedFileBytes == null)
                const Icon(
                  Icons.eco,
                  size: 100,
                  color: Color(0xFF8A9A5B),
                )
              else
                Hero(
                  tag: 'plantImage',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _selectedFileBytes!,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing plant details...', style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                )
              else if (_plantInfo != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _plantInfo!.commonName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8A9A5B),
                          ),
                        ),
                        Text(
                          _plantInfo!.scientificName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF708090),
                          ),
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Fun Fact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC04000),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _plantInfo!.funFact,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF708090)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Column(
                  children: [
                    Text(
                      'Discover Your Plant\'s Potential',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF708090),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Identify plants and get care tips powered by Gemini AI.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF708090),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickAndIdentifyImage,
                icon: const Icon(Icons.add_a_photo),
                label: Text(_isLoading ? 'Scanning...' : 'Scan Plant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
