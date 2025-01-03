import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamRegistrationScreen extends StatefulWidget {
  @override
  _TeamRegistrationScreenState createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends State<TeamRegistrationScreen> {
  final TextEditingController teamNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _registerTeam() async {
    if (teamNameController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('teams').add({
          'name': teamNameController.text.trim(),
          'description': descriptionController.text.trim(),
          'createdBy': user.uid,
          'createdAt': Timestamp.now(),
          'followers': [], // Initialize with an empty list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Team registered successfully!')),
        );

        // Clear the input fields
        teamNameController.clear();
        descriptionController.clear();
      }
    } catch (e) {
      print('Error registering team: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering team. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

 void followTeam(String teamId, String userId, String username) async {
  try {
    final teamRef = FirebaseFirestore.instance.collection('teams').doc(teamId);

    // Fetch team document
    var teamDoc = await teamRef.get();

    // Get current followers list or initialize it as an empty list
    List<String> followers = List<String>.from(teamDoc.data()?['followers'] ?? []);

    if (!followers.contains(userId)) {
      // Add the user to the followers list
      followers.add(userId);

      // Update the Firestore document
      await teamRef.update({
        'followers': followers,
        'followersCount': FieldValue.increment(1), // Increment follower count
      });

      print("$username followed the team.");
    } else {
      // User has already followed the team
      print("User has already followed this team.");
    }
  } catch (e) {
    print('Error following team: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Team'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('teams').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No teams found.'));
                }

                final teams = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final followers = List.from(team['followers']);
                    final isFollowing = followers.contains(_auth.currentUser?.uid);

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(team['name']),
                        subtitle: Text(team['description']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${followers.length} Followers'),
                            IconButton(
                              icon: Icon(
                                isFollowing ? Icons.favorite : Icons.favorite_border,
                                color: isFollowing ? Colors.red : null,
                              ),
                              onPressed: () => (team.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _isLoading
              ? CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: teamNameController,
                        decoration: InputDecoration(labelText: 'Team Name'),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _registerTeam,
                        child: Text('Register Team'),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
