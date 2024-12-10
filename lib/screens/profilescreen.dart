import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:sportmate/screens/LoginScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;
  String? _uploadedVideoUrl;

  // Function to fetch user data from Firestore
  Future<DocumentSnapshot> _getUserData() async {
    User? user = _auth.currentUser;
    return _firestore.collection('users').doc(user?.uid).get();
  }

  // Function to sign out user
  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // Uploading video to Cloudinary
  Future<void> _uploadVideo() async {
    User? user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('User not logged in');
      return;
    }

    try {
      // Pick a video file
      final XFile? videoFile = await _picker.pickVideo(source: ImageSource.gallery);

      if (videoFile == null) {
        _showSnackBar('No video selected');
        return;
      }

      // Validate file size
      final file = File(videoFile.path);
      if (file.lengthSync() > 50 * 1024 * 1024) {
        _showSnackBar('File size exceeds 50MB');
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Prepare video upload to Cloudinary
      String fileName = "${user.uid}_skill_video.mp4";
      Uri uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/djusnuweg/video/upload');
      Map<String, String> uploadData = {
        'upload_preset': 'sportsmatevideo',
        'public_id': fileName,
      };

      http.MultipartRequest request = http.MultipartRequest('POST', uploadUrl)
        ..headers.addAll({'Content-Type': 'multipart/form-data'})
        ..fields.addAll(uploadData);

      // Adding the video file to the request (handling web vs mobile platforms)
      if (kIsWeb) {
        final fileBytes = await videoFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType('video', 'mp4'),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('video', 'mp4'),
        ));
      }

      // Send the request to Cloudinary
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse response and save URL to Firestore
        final responseData = jsonDecode(response.body);
        String videoUrl = responseData['secure_url'];

        await _firestore.collection('users').doc(user.uid).update({
          'skillVideo': videoUrl,
        });

        setState(() {
          _uploadedVideoUrl = videoUrl;
        });

        _showSnackBar('Video uploaded successfully!');
      } else {
        _showSnackBar('Error uploading video to Cloudinary');
      }
    } catch (e) {
      _showSnackBar('Error uploading video');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Show SnackBar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
        backgroundColor: Color(0xFF2196F3),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: _getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error loading profile"));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("Profile not found"));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        userData['profilePicture'] ?? 'https://via.placeholder.com/150',
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Name: ${userData['name'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Email: ${userData['email'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadVideo,
                    icon: Icon(Icons.upload_file),
                    label: _isUploading
                        ? Text('Uploading...')
                        : Text('Upload Skill Video'),
                  ),
                  SizedBox(height: 20),
                  userData['skillVideo'] != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Skill Video:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            VideoPreview(userData['skillVideo']),
                          ],
                        )
                      : Text('No skill video uploaded yet.', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Widget to display video preview
class VideoPreview extends StatefulWidget {
  final String videoUrl;

  VideoPreview(this.videoUrl);

  @override
  _VideoPreviewState createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // Refresh state to display the video
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
}
