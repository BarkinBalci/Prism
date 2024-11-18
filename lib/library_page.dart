import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:prism/camera_page.dart';
import 'package:prism/video_player.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  double _uploadProgress = 0.0;
  List<String> _videoUrls = [];

  @override
  void initState() {
    super.initState();
    _fetchVideoUrls();
  }

  Future<void> _fetchVideoUrls() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }
      final storageRef =
          FirebaseStorage.instance.ref().child('videos/${user.uid}');
      final ListResult result = await storageRef.listAll();
      final List<String> urls = await Future.wait(
          result.items.map((ref) => ref.getDownloadURL()).toList());
      setState(() {
        _videoUrls = urls;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching videos: $e')),
      );
    }
  }

  Future<void> uploadVideoToFirebase(XFile videoFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('videos/${user.uid}/${videoFile.name}');
      final uploadTask = storageRef.putFile(File(videoFile.path));

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress =
              event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
        });
      });

      await uploadTask;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully')),
      );
      _fetchVideoUrls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading video: $e')),
      );
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
        bottom: _uploadProgress > 0 && _uploadProgress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(value: _uploadProgress),
              )
            : null,
      ),
      body: _videoUrls.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1 / 1,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: _videoUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    //TODO play video
                  },
                  child: VideoPlayerWidget(url: _videoUrls[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final videoFile = await Navigator.push<XFile>(
            context,
            MaterialPageRoute(builder: (context) => const CameraPage()),
          );
          if (videoFile != null) {
            await uploadVideoToFirebase(videoFile);
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}