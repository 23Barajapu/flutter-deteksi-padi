import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'roboflow_service.dart';

void main() {
  runApp(const RiceDiseaseApp());
}

class RiceDiseaseApp extends StatelessWidget {
  const RiceDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rice Disease Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DetectionScreen(),
    );
  }
}

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  File? _image;
  List<dynamic>? _predictions;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final RoboflowService _roboflowService = RoboflowService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _predictions = null;
        });
        _detectImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _detectImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await _roboflowService.detectDisease(_image!);
      setState(() => _predictions = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting disease: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rice Disease Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 300, fit: BoxFit.cover),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No image selected.\nPick an image to detect rice disease.',
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_predictions != null && _predictions!.isNotEmpty)
                Column(
                  children: _predictions!.map((p) {
                    final confidence = (p['confidence'] * 100).toStringAsFixed(1);
                    return ListTile(
                      title: Text(p['class'].toString().toUpperCase()),
                      trailing: Text('$confidence%'),
                      leading: const Icon(Icons.bug_report, color: Colors.red),
                    );
                  }).toList(),
                )
              else if (_predictions != null && _predictions!.isEmpty)
                const Text('No disease detected.', style: TextStyle(color: Colors.green, fontSize: 18)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.camera),
            tooltip: 'Take a Photo',
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: 'Pick from Gallery',
            heroTag: 'gallery',
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }
}
