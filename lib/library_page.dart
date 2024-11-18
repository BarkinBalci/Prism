import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late CameraController controller;
  String _errorMessage = '';

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
              _errorMessage = 'Camera access denied without prompt. Please enable camera access in settings.';
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
      body: Center(
        child: controller.value.isInitialized
            ? CameraPreview(controller)
            : _errorMessage.isNotEmpty
                ? Text(_errorMessage)
                : const CircularProgressIndicator(),
      ),
    );
  }
}
