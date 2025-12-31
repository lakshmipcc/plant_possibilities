import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'gemini_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String sessionID = 'SESSION_${DateTime.now().millisecondsSinceEpoch}';
  print('DEBUG: App Starting. [$sessionID]');
  try {
    await dotenv.load(fileName: "assets/.env");
    print('DEBUG: .env load sequence finished.');
  } catch (e) {
    print('DEBUG: .env FATAL ERROR: $e');
  }

  // Global Error Handler for "White Screen of Death"
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Examples of App Crash:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(details.exceptionAsString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text('Stack Trace (Snippet): ${details.stack.toString().split('\n').take(3).join('\n')}', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

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
      title: 'Plant Possibilities v2.2',
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedFileBytes;
  PlantInfo? _plantInfo;
  bool _isLoading = false;

  Future<void> _handleImageAction(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final name = image.name;

        setState(() {
          _selectedFileBytes = bytes;
          _plantInfo = null;
          _isLoading = true;
        });

        final data = await _geminiService.identifyPlant(bytes, name);
        setState(() {
          _plantInfo = PlantInfo.fromJson(data);
        });
      }
    } catch (e) {
      print('APP ERROR: $e'); // Log to console for terminal debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to Identify: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: [
                          Text('Error: $e'),
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Time: ${DateTime.now().toIso8601String()}'),
                          // Note: We don't have access to the raw key here easily without hacking, 
                          // but this detailed error might contain the API response "API_KEY_EXPIRED".
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Plant Possibilities'),
            Text(
              'v3.5 (NoCrash) - ${DateTime.now().toIso8601String().substring(0, 16)}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
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
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.memory(
                              _selectedFileBytes!,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 24),
                          Text(
                            'Examining your plant...',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 18,
                              color: Color(0xFF708090),
                            ),
                          ),
                        ],
                      )
                    else if (_plantInfo != null)
                      _buildPlantCard()
                    else
                      _buildWelcomeText(),
                    const SizedBox(height: 48),
                    if (!_isLoading) _buildActionButtons(isNarrow),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      children: [
        Text(
          'Identify Your Garden',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF708090),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Snap a photo or upload an image to discover your plant\'s hidden story.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF708090)),
        ),
      ],
    );
  }

  Widget _buildPlantCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: const Color(0xFF8A9A5B).withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _plantInfo!.commonName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8A9A5B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _plantInfo!.scientificName,
              style: const TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: Color(0xFF708090),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 12),
                const Text(
                  'Fun Fact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC04000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _plantInfo!.funFact,
              style: const TextStyle(fontSize: 17, color: Color(0xFF4A4A4A), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isNarrow) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleImageAction(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Take Photo'),
          style: ElevatedButton.styleFrom(
            minimumSize: isNarrow ? const Size(double.infinity, 56) : const Size(200, 56),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _handleImageAction(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Upload Image'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            side: const BorderSide(color: Color(0xFFC04000), width: 2),
            foregroundColor: const Color(0xFFC04000),
            minimumSize: isNarrow ? const Size(double.infinity, 56) : const Size(200, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
