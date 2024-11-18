import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prism/camera_page.dart';
import 'package:prism/thumbnail.dart';
import 'package:prism/video_player_page.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  double _uploadProgress = 0.0;
  List<String> _videoUrls = [];
  bool _isSelectionMode = false;
  List<String> _selectedVideos = [];

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
          .child('videos/${user.uid}/${videoFile.name}.mp4');
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

  Future<void> _deleteSelectedVideos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }
      for (String url in _selectedVideos) {
        String fileName = url.split('%2F').last.split('?').first;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('videos/${user.uid}/$fileName');

        await storageRef.delete();
      }
      setState(() {
        _isSelectionMode = false;
        _selectedVideos = [];
      });
      _fetchVideoUrls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: $e')),
      );
    }
  }

  Future<void> _shareSelectedVideos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }

      final List<Future<String>> videoLinks = _selectedVideos.map((url) {
        final fileName = url.split('%2F').last.split('?').first;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('videos/${user.uid}/$fileName');
        return storageRef.getDownloadURL();
      }).toList();

      final List<String> resolvedLinks = await Future.wait(videoLinks);

      final String shareText = resolvedLinks.join('\n');

      await Share.share(shareText, subject: 'Check out these videos!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing videos: $e')),
      );
    }
  }

  void _onVideoLongPress(String url) {
    setState(() {
      _isSelectionMode = true;
      _selectedVideos.add(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        title: const Text('Prism'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: () async => await _shareSelectedVideos(),
              icon: const Icon(Icons.share),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text(
                        'Are you sure you want to delete the selected videos? This action is permanent and cannot be undone!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _deleteSelectedVideos();
                }
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ],
        bottom: _uploadProgress > 0 && _uploadProgress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(value: _uploadProgress),
              )
            : null,
      ),
      body: _videoUrls.isEmpty
          ? const Center(child: Text("Your gallery is empty."))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1 / 1,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: _videoUrls.length,
              itemBuilder: (context, index) {
                final url = _videoUrls[index];
                final isSelected = _selectedVideos.contains(url);
                return GestureDetector(
                  onLongPress: () => _onVideoLongPress(url),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerPage(url: url),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      ThumbnailWidget(url: url),
                      if (isSelected)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
