import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportmate/cloudinary_service.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rulesController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController organizerController = TextEditingController();

  File? _selectedFile;
  String? _selectedFileUrl;
  String? _fileType; // "image" or "video"

  String postType = "normal";
  String? selectedSport;
  bool _isLoading = false;
  String? _username;

  final List<String> sportsList = [
    'Cricket',
    'Kabaddi',
    'Chess',
    'Football',
    'Workshop',
    'Symposium',
    'Others'
  ];

  final CloudinaryService cloudinaryService = CloudinaryService(
    cloudName: 'djusnuweg',
    apiKey: '933488682224341',
    apiSecret: 'JA13vW11QltMLD9clvAYPuOHScA',
    uploadPreset: 'sportsmate',
  );

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _username = userDoc['username'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _pickMedia(String type) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (type == 'image') {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else if (type == 'video') {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      try {
        String? uploadedUrl;

        if (kIsWeb) {
          final fileBytes = await pickedFile.readAsBytes();
          final mimeType = pickedFile.name.split('.').last;
          uploadedUrl = await cloudinaryService.uploadMediaFromBytes(
            fileBytes,
            fileName: pickedFile.name,
            mimeType: mimeType,
          );
        } else {
          uploadedUrl = await cloudinaryService.uploadMedia(pickedFile.path);
        }

        if (uploadedUrl != null) {
          setState(() {
            _selectedFileUrl = uploadedUrl;
            _fileType = type;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$type uploaded successfully!')),
          );
        }
      } catch (e) {
        print('Error uploading $type: $e');
      }
    }
  }

  Future<void> _showDatePicker(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      controller.text = pickedDate.toLocal().toString().split(' ')[0];
    }
  }

  Future<void> _createPost() async {
  if (_isLoading ||
      _username == null ||
      _selectedFileUrl == null ||
      selectedSport == null ||
      startDateController.text.trim().isEmpty ||
      endDateController.text.trim().isEmpty ||
      (postType == "tournament" && organizerController.text.trim().isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill all required fields.')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Parse the dates from the date pickers
    DateTime startDate = DateTime.parse(startDateController.text.trim());
    DateTime endDate = DateTime.parse(endDateController.text.trim());
    DateTime currentDate = DateTime.now();

    // Determine tournament status based on the dates
    String tournamentStatus;
    if (currentDate.isBefore(startDate)) {
      tournamentStatus = "Upcoming";
    } else if (currentDate.isAfter(endDate)) {
      tournamentStatus = "Completed";
    } else {
      tournamentStatus = "Ongoing";
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'rules': rulesController.text.trim(),
      'location': locationController.text.trim(),
      'startDate': startDateController.text.trim(),
      'endDate': endDateController.text.trim(),
      'fileUrl': _selectedFileUrl,
      'fileType': _fileType,
      'createdAt': Timestamp.now(),
      'postType': postType,
      'organizer': postType == "tournament"
          ? organizerController.text.trim()
          : null,
      'sport': selectedSport,
      'username': _username,
      'likes': 0,
      'status': postType == "tournament" ? tournamentStatus : null, // Add status
    });

    await _rewardUser();

    _clearFormFields();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post created successfully!')),
    );
  } catch (e) {
    print('Error creating post: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating post. Please try again.')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<void> _rewardUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(userRef);

          if (snapshot.exists) {
            int postCount = snapshot['postCount'] ?? 0;
            postCount += 1;

            transaction.update(userRef, {'postCount': postCount});

            if (postCount % 5 == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '🎉 Milestone Reward! You have created $postCount posts.')),
              );
            }
          }
        });
      }
    } catch (e) {
      print('Error rewarding user: $e');
    }
  }

  void _clearFormFields() {
    titleController.clear();
    descriptionController.clear();
    rulesController.clear();
    locationController.clear();
    startDateController.clear();
    endDateController.clear();
    organizerController.clear();
    setState(() {
      _selectedFile = null;
      _selectedFileUrl = null;
      selectedSport = null;
      postType = "normal";
      _fileType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: rulesController,
                    decoration: InputDecoration(labelText: 'Rules (optional)'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedSport,
                    items: sportsList
                        .map((sport) => DropdownMenuItem(
                              value: sport,
                              child: Text(sport),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSport = value;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Select Sport/Event'),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(labelText: 'Location'),
                  ),
                  TextField(
                    controller: startDateController,
                    decoration: InputDecoration(labelText: 'Start Date'),
                    onTap: () => _showDatePicker(startDateController),
                    readOnly: true,
                  ),
                  TextField(
                    controller: endDateController,
                    decoration: InputDecoration(labelText: 'End Date'),
                    onTap: () => _showDatePicker(endDateController),
                    readOnly: true,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          value: 'normal',
                          groupValue: postType,
                          onChanged: (value) {
                            setState(() {
                              postType = value.toString();
                            });
                          },
                          title: Text('Normal'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          value: 'tournament',
                          groupValue: postType,
                          onChanged: (value) {
                            setState(() {
                              postType = value.toString();
                            });
                          },
                          title: Text('Tournament'),
                        ),
                      ),
                    ],
                  ),
                  if (postType == "tournament")
                    TextField(
                      controller: organizerController,
                      decoration: InputDecoration(labelText: 'Organizer'),
                    ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _pickMedia('image'),
                    child: Text('Upload Image'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickMedia('video'),
                    child: Text('Upload Video'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createPost,
                    child: Text('Create Post'),
                  ),
                ],
              ),
            ),
    );
  }
}
