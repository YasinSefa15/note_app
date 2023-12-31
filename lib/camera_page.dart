import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:note_app/note.dart';

class CameraPage extends StatefulWidget {
  final Function()? refreshProfile;
  final Note? note;
  const CameraPage({Key? key, this.refreshProfile, this.note})
      : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  File? _capturedImage;
  final picker = ImagePicker();
  late List<CameraDescription> _cameras;
  late int _selectedCameraIndex;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _selectedCameraIndex = 0; // Default: Use the first available camera
    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
    );

    _initializeControllerFuture = _cameraController.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _captureAndDisplayPhoto() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      setState(() {
        _capturedImage = File(image.path);
      });
    } catch (e) {
      print('Error capturing photo: $e');
    }
  }

  void _resetCapture() {
    setState(() {
      _capturedImage = null;
    });
  }

  Future<void> _openGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveAndNavigateToDetails() async {
    try {
      if (widget.note != null) {
        if (_capturedImage != null) {
          Navigator.pop(context, _capturedImage!.path);
        }
      }
    } catch (e) {
      print('Error saving and navigating: $e');
    }
  }

  Future<void> _toggleCamera() async {
    int newCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    _selectedCameraIndex = newCameraIndex;
    await _cameraController.dispose();
    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
    );

    setState(() {
      _initializeControllerFuture = _cameraController.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Camera'),
            IconButton(
              onPressed: _toggleCamera,
              icon: const Icon(Icons.switch_camera),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _capturedImage != null
                ? Image.file(
                    _capturedImage!,
                    fit: BoxFit.cover,
                  )
                : FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return CameraPreview(_cameraController);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
          ),
          if (_capturedImage != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _resetCapture();
                  },
                  child: const Text('Back'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _saveAndNavigateToDetails,
                  child: const Text('Add'),
                ),
              ],
            ),
          if (_capturedImage == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _captureAndDisplayPhoto,
                  icon: const Icon(Icons.camera),
                  label: const Text('Take Photo'),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _openGallery,
                  icon: const Icon(Icons.photo),
                  label: const Text('Open Gallery'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
