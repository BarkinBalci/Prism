import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late CameraController controller;
  String _errorMessage = '';
  bool _isRecording = false;
  XFile? _videoFile;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      controller = CameraController(cameras[0], ResolutionPreset.max);
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (e is CameraException) {
        setState(() {
          switch (e.code) {
            case 'CameraAccessDenied': //Thrown when user denies the camera access permission.
              _errorMessage = 'Camera access denied';
              break;
            case 'CameraAccessDeniedWithoutPrompt': //iOS only for now. Thrown when user has previously denied the permission. iOS does not allow prompting alert dialog a second time. Users will have to go to Settings > Privacy > Camera in order to enable camera access.
              _errorMessage =
                  'Camera access denied without prompt. Please enable camera access in settings.';
              break;
            case 'CameraAccessRestricted': //iOS only for now. Thrown when camera access is restricted and users cannot grant permission (parental control).
              _errorMessage = 'Camera access restricted';
              break;
            case 'AudioAccessDenied': //Thrown when user denies the audio access permission.
              _errorMessage = 'Audio access denied';
              break;
            case 'AudioAccessDeniedWithoutPrompt': //iOS only for now. Thrown when user has previously denied the permission. iOS does not allow prompting alert dialog a second time. Users will have to go to Settings > Privacy > Microphone in order to enable audio access.
              _errorMessage =
                  'Audio access denied without prompt. Please enable audio access in settings.';
              break;
            case 'AudioAccessRestricted': //iOS only for now. Thrown when audio access is restricted and users cannot grant permission (parental control).
              _errorMessage = 'Audio access restricted';
              break;
            default:
              _errorMessage = 'An unknown error occurred';
              break;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    if (!controller.value.isInitialized) {
      return;
    }
    if (controller.value.isRecordingVideo) {
      return;
    }
    try {
      await controller.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting video recording: $e';
      });
    }
  }

  Future<void> stopRecording() async {
    if (!controller.value.isRecordingVideo) {
      return;
    }
    try {
      _videoFile = await controller.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      if (_videoFile != null) {
        await uploadVideoToFirebase(_videoFile!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error stopping video recording: $e';
      });
    }
  }

  Future<void> uploadVideoToFirebase(XFile videoFile) async {
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('videos/${videoFile.name}');
      final uploadTask = storageRef.putFile(File(videoFile.path));
      await uploadTask;
      setState(() {
        _errorMessage = 'Video uploaded successfully';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading video: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prism'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.value.isInitialized)
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          if (_errorMessage.isNotEmpty)
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRecording ? null : startRecording,
                child: Text('Start Recording'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isRecording ? stopRecording : null,
                child: Text('Stop Recording'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
