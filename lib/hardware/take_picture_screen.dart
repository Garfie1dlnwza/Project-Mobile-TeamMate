import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class TakePictureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const TakePictureScreen({super.key, required this.cameras});

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  File? _imageFile;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();

    // Initialize the first available camera
    _controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
    );

    // Initialize the controller
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  // Function to toggle between front and back cameras
  void _toggleCamera() {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _controller = CameraController(
        widget.cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _controller.initialize();
    });
  }

  Future<String> getImagePath() async {
    if (kIsWeb) {
      // สำหรับ Web ให้ใช้ path บน web
      return '/tmp/${DateTime.now().millisecondsSinceEpoch}.png';
    } else {
      // สำหรับ Mobile
      final tempDir = await getTemporaryDirectory();
      return '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    }
  }

  // Function to take a picture
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      XFile imageFile = await _controller.takePicture();

      if (kIsWeb) {
        Uint8List bytes = await imageFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
        _showWebPicturePreview(bytes);
      } else {
        String imagePath = await getImagePath();
        await imageFile.saveTo(imagePath);
        setState(() {
          _imageFile = File(imagePath);
        });
        _showPicturePreview(imagePath);
      }
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
    }
  }

  void _showWebPicturePreview(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: const Text(
                'Picture Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: Image.memory(imageBytes),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Handle web image usage
                },
                child: const Text(
                  'Use Photo',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  // Show picture preview and confirmation dialog
  void _showPicturePreview(String imagePath) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: const Text(
                'Picture Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content:
                kIsWeb
                    ? Image.network(imagePath) // Load from network or memory
                    : Image.file(
                      File(imagePath),
                    ), // Load from local file on mobile
            actions: [
              TextButton(
                onPressed: () {
                  // Discard the image
                  Navigator.of(context).pop();
                  if (_imageFile != null) {
                    _imageFile!.delete();
                  }
                },
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // ❌❌❌❌❌❌❌❌ ยังไม่ได้ implement ให้เอาไปเก็บในไฟล์ หรือเอาไปใช้
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(File(imagePath));
                },
                child: const Text(
                  'Use Photo',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Take a Picture',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera, color: Colors.black),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If the Future is complete, display the camera preview
                  return CameraPreview(_controller);
                } else {
                  // Otherwise, display a loading indicator
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt, color: Colors.black),
      ),
    );
  }
}
