import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;
  bool _isRecording = false;
  XFile? _videoFile;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      controller =
          CameraController(cameras![selectedCameraIndex], ResolutionPreset.max);
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (e is CameraException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.description}')),
        );
      }
    }
  }

  Future<void> switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    await controller.dispose();
    controller =
        CameraController(cameras![selectedCameraIndex], ResolutionPreset.max);
    await controller.initialize();
    setState(() {});
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error starting video recording')),
      );
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
        Navigator.pop(context, _videoFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error stopping video recording')),
      );
    }
  }

  Future<void> pickVideoFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      _videoFile = pickedFile;
      Navigator.pop(context, _videoFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (controller.value.isInitialized)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CameraPreview(controller),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: pickVideoFromGallery,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.photo, color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isRecording ? stopRecording : startRecording,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: switchCamera,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.loop, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
