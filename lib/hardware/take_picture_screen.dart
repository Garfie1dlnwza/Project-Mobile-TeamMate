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

class _TakePictureScreenState extends State<TakePictureScreen>
    with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  File? _imageFile;
  Uint8List? _webImage;
  bool _isFlashOn = false;
  double _zoomLevel = 1.0;
  bool _isCameraReady = false;

  // Animation controllers
  late AnimationController _shutterAnimationController;
  late AnimationController _flashAnimationController;

  // Focus point
  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _shutterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize the first available camera
    _initCamera(widget.cameras[_selectedCameraIndex]);
  }

  void _initCamera(CameraDescription camera) {
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize the controller
    _initializeControllerFuture = _controller
        .initialize()
        .then((_) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isCameraReady = true;
          });

          // Set initial flash mode
          _controller.setFlashMode(FlashMode.off);
        })
        .catchError((e) {
          print("Camera initialization error: $e");
        });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed
    _controller.dispose();
    _shutterAnimationController.dispose();
    _flashAnimationController.dispose();
    super.dispose();
  }

  // Function to toggle between front and back cameras
  void _toggleCamera() {
    setState(() {
      _isCameraReady = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _initCamera(widget.cameras[_selectedCameraIndex]);
    });
  }

  // Toggle flash
  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);

      if (_isFlashOn) {
        _flashAnimationController.forward();
      } else {
        _flashAnimationController.reverse();
      }
    });
  }

  // Set focus on tap
  Future<void> _onTapToFocus(TapDownDetails details) async {
    if (_controller.value.isInitialized) {
      final double x = details.localPosition.dx;
      final double y = details.localPosition.dy;

      // Get the size of the preview
      final double previewWidth = MediaQuery.of(context).size.width;
      final double previewHeight = _controller.value.aspectRatio * previewWidth;

      // Convert to normalized device coordinates (between -1 and 1)
      final double xp = (x / previewWidth) * 2 - 1;
      final double yp = ((y / previewHeight) * 2 - 1) * -1;

      // Only set focus if within the preview
      if (y < previewHeight) {
        setState(() {
          _focusPoint = details.localPosition;
        });

        try {
          await _controller.setFocusPoint(Offset(xp, yp));
          await _controller.setExposurePoint(Offset(xp, yp));

          // Remove focus point after delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _focusPoint = null;
              });
            }
          });
        } catch (e) {
          print('Error setting focus: $e');
        }
      }
    }
  }

  Future<String> getImagePath() async {
    if (kIsWeb) {
      // For Web
      return '/tmp/${DateTime.now().millisecondsSinceEpoch}.png';
    } else {
      // For Mobile
      final tempDir = await getTemporaryDirectory();
      return '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    }
  }

  // Function to take a picture
  Future<void> _takePicture() async {
    if (!_isCameraReady) return;

    try {
      // Play shutter animation
      _shutterAnimationController.forward(from: 0.0);

      // If flash is on, simulate flash effect
      if (_isFlashOn) {
        _flashAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 100));
        _flashAnimationController.reverse();
      }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWebPicturePreview(Uint8List imageBytes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildImagePreviewSheet(
            imageWidget: Image.memory(imageBytes, fit: BoxFit.cover),
            isWeb: true,
            onConfirm: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(_webImage);
            },
          ),
    );
  }

  // Show picture preview in a bottom sheet
  void _showPicturePreview(String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildImagePreviewSheet(
            imageWidget:
                kIsWeb
                    ? Image.network(imagePath, fit: BoxFit.cover)
                    : Image.file(File(imagePath), fit: BoxFit.cover),
            isWeb: false,
            onConfirm: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(File(imagePath));
            },
          ),
    );
  }

  Widget _buildImagePreviewSheet({
    required Widget imageWidget,
    required bool isWeb,
    required VoidCallback onConfirm,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Image preview
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: imageWidget,
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Discard button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (_imageFile != null && !isWeb) {
                        _imageFile!.delete();
                      }
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Discard',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Use photo button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Use Photo',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Animation for the shutter effect
    final Animation<double> shutterAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(
      CurvedAnimation(
        parent: _shutterAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Flash overlay animation
    final Animation<double> flashAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _flashAnimationController, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Flash toggle
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
            onPressed: _isCameraReady ? _toggleFlash : null,
          ),

          // Camera toggle
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flip_camera_ios, color: Colors.white),
            ),
            onPressed: _isCameraReady ? _toggleCamera : null,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview with tap to focus
          GestureDetector(
            onTapDown: _isCameraReady ? _onTapToFocus : null,
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If the Future is complete, display the camera preview
                  return CameraPreview(_controller);
                } else {
                  // Otherwise, display a loading indicator
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
              },
            ),
          ),

          // Flash overlay
          FadeTransition(
            opacity: flashAnimation,
            child: Container(color: Colors.white.withOpacity(0.7)),
          ),

          // Focus indicator
          if (_focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 20,
              top: _focusPoint!.dy - 20,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Zoom slider
          if (_isCameraReady)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                    Expanded(
                      child: Slider(
                        value: _zoomLevel,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        onChanged: (value) {
                          setState(() {
                            _zoomLevel = value;
                          });
                          _controller.setZoomLevel(value);
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 24,
              ),
            ),

            // Capture button
            ScaleTransition(
              scale: shutterAnimation,
              child: GestureDetector(
                onTap: _isCameraReady ? _takePicture : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: 4),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Placeholder for balance
            const SizedBox(width: 50, height: 50),
          ],
        ),
      ),
    );
  }
}
