import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportmate/cloudinary_service.dart';
import 'package:sportmate/distance_util.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController additionalInfoController = TextEditingController();
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
  double? _distance;

  String postAccountType = "personal"; // Default to personal

  final List<String> sportsList = [
    'Cricket',
    'Kabaddi',
    'Chess',
    'Football',
    'VollyBall',
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
    _calculateDistance(); // Call it when screen loads
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
   Future<void> _calculateDistance() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Assuming you have event location coordinates (latitude and longitude)
      double eventLat = 12.971598; // Replace with actual latitude
      double eventLon = 77.594566; // Replace with actual longitude

      double distance = DistanceUtil.calculateDistance(
        position.latitude, position.longitude, eventLat, eventLon,
      );

      setState(() {
        _distance = distance;
      });
    } catch (e) {
      print('Error fetching location or calculating distance: $e');
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
    if (_isLoading || _username == null || 
        _selectedFileUrl == null || selectedSport == null || 
        startDateController.text.trim().isEmpty || 
        endDateController.text.trim().isEmpty || 
        (postType == "tournament" && organizerController.text.trim().isEmpty)) {
        
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }
    
    setState(() { _isLoading = true; });
    
    try {
      DateTime startDate = DateTime.parse(startDateController.text.trim());
      DateTime endDate = DateTime.parse(endDateController.text.trim());
      DateTime currentDate = DateTime.now();

      String tournamentStatus;
      if (currentDate.isBefore(startDate)) {
        tournamentStatus = "Upcoming";
      } else if (currentDate.isAfter(endDate)) {
        tournamentStatus = "Completed";
      } else {
        tournamentStatus = "Ongoing";
      }

      String collectionName =
          postAccountType == "team" ? 'teamPosts' : 'posts';
      
      await FirebaseFirestore.instance.collection(collectionName).add({
        'additionalInfo': additionalInfoController.text.trim(),
        'location': locationController.text.trim(),
        'startDate': startDateController.text.trim(),
        'endDate': endDateController.text.trim(),
        'fileUrl': _selectedFileUrl,
        'fileType': _fileType,
        'createdAt': Timestamp.now(),
        'postType': postType,
        'organizer': postType == "tournament" ? organizerController.text.trim() : null,
        'sport': selectedSport,
        'username': _username,
        'likes': 0,
        'status': postType == "tournament" ? tournamentStatus : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post created successfully!')),
      );
      
    } catch (e) {
      print('Error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post. Please try again.')),
      );
      
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _clearFormFields() {
    additionalInfoController.clear();
    locationController.clear();
    startDateController.clear();
    endDateController.clear();
    organizerController.clear();

    setState(() {
      _selectedFile = null;
      _selectedFileUrl = null;
      selectedSport = null;
      postType = "normal";
      postAccountType = "personal"; // Reset to personal
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
      body: _isLoading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [if (_distance != null)
              Text('Distance to event: ${_distance!.toStringAsFixed(2)} km'),
            // Dropdown or Radio buttons for selecting account type
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text("Personal"),
                    value: "personal",
                    groupValue: postAccountType,
                    onChanged: (value) { setState(() { postAccountType = value!; }); },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text("Team"),
                    value: "team",
                    groupValue: postAccountType,
                    onChanged: (value) { setState(() { postAccountType = value!; }); },
                  ),
                ),
              ],
            ),
            
            // Additional Info Field
            TextField(
              controller: additionalInfoController,
              decoration: InputDecoration(labelText: 'Write something (optional)'),
            ),

            // Sport Selection
            DropdownButtonFormField<String>(
              value: selectedSport,
              items: sportsList.map((sport) => DropdownMenuItem(
                value: sport,
                child: Text(sport),
              )).toList(),
              onChanged:(value){ setState(() { selectedSport=value; }); },
              decoration: InputDecoration(labelText:'Select Sport/Event'),
            ),

            // Location Field
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText:'Location'),
            ),

            // Start Date Field
            TextField(
              controller:startDateController,
              decoration: InputDecoration(labelText:'Start Date'),
              onTap:( )=>_showDatePicker(startDateController),
              readOnly:true,
            ),

            // End Date Field
            TextField(
              controller:endDateController,
              decoration: InputDecoration(labelText:'End Date'),
              onTap:( )=>_showDatePicker(endDateController),
              readOnly:true,
            ),

            // Post Type Selection
            Row(children:[
              Expanded(child:
                RadioListTile(value:'normal',groupValue: postType,onChanged:(value){
                  setState(() { postType=value.toString(); });
                },title: Text('Normal'),),
              ),
              Expanded(child:
                RadioListTile(value:'tournament',groupValue: postType,onChanged:(value){
                  setState(() { postType=value.toString(); });
                },title: Text('Tournament'),),
              ),
            ],),

            // Organizer Field only for tournament
            if(postType=="tournament") 
              TextField(controller: organizerController,decoration: InputDecoration(labelText:'Organizer'),),

            // Upload Buttons with Thumbnails
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _pickMedia('image'),
                  child: Text('Upload Image'),
                ),
                ElevatedButton(
                  onPressed: () => _pickMedia('video'),
                  child: Text('Upload Video'),
                ),
              ],
            ),

            // Show thumbnail preview if a file is selected
            SizedBox(height: 20),
            if (_selectedFile != null)
              Column(
                children: [
                  Text("Selected ${_fileType}:"),
                  SizedBox(height: 10),
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.grey, width: 1),
                    ),
                    child:_fileType == "image"
                        ? Image.file(_selectedFile!, fit: BoxFit.cover)
                        : Icon(Icons.videocam, size: 50), // Placeholder for video thumbnail
                  ),
                ],
              ),
            
            SizedBox(height: 20),

            ElevatedButton(onPressed:_createPost,child: Text('Create Post'),),
            if (_isLoading)
  Padding(
    padding: const EdgeInsets.only(top: 10),
    child: LinearProgressIndicator(), // Optional additional loading indicator
  ),
            
            // Show loading indicator while uploading
            
          ],
        ),
      ),
    );
  }
}
