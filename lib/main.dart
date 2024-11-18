import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<MyApp> {
  late CameraController controller;
  bool _isCameraVisible = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        setState(() {
          switch (e.code) {
            case 'CameraAccessDenied': //Thrown when user denies the camera access permission.
              _errorMessage = 'Camera access denied';
              break;
            case 'CameraAccessDeniedWithoutPrompt': //iOS only for now. Thrown when user has previously denied the permission. iOS does not allow prompting alert dialog a second time. Users will have to go to Settings > Privacy > Camera in order to enable camera access.
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
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('DemoApp'),
        ),
        body: Center(
          child: _isCameraVisible
              ? (controller.value.isInitialized
                  ? CameraPreview(controller)
                  : _errorMessage.isNotEmpty
                      ? Text(_errorMessage)
                      : const CircularProgressIndicator())
              : const Text('Press the button to open the camera'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isCameraVisible = !_isCameraVisible;
            });
          },
          child: const Icon(Icons.camera),
        ),
      ),
    );
  }
}