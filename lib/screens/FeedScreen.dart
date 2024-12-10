import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportmate/screens/PostDetailScreen.dart';
import 'package:sportmate/screens/profilescreen.dart';
import 'package:sportmate/video_player_widget.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatelessWidget {
  void likePost(String postId, String userId, String username) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

      var postDoc = await postRef.get();
      List<String> likedUsers = List<String>.from(postDoc.data()?['likedUsers'] ?? []);

      if (!likedUsers.contains(userId)) {
        likedUsers.add(userId);

        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedUsers': likedUsers,
        });

        print("$username liked the post.");
      } else {
        print("User has already liked this post.");
      }
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Events"),
        centerTitle: true,
        backgroundColor: Color(0xFF2196F3),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.card_giftcard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RewardScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
        },
        backgroundColor: Color(0xFF2196F3),
        child: Icon(Icons.add),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading posts",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "No posts available",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var post = snapshot.data!.docs[index];
                var data = post.data() as Map<String, dynamic>;
                String postId = post.id;
                String content = data['content'] ?? '';
                String username = data['username'] ?? 'Anonymous';
                String userId = data['authorId'] ?? '';
                int likes = data['likes'] ?? 0;
                String imageUrl = data['fileUrl'] ?? '';
                String videoUrl = data['videoUrl'] ?? '';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(postId: postId),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.all(10.0),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text(
                            username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          ),
                        if (videoUrl.isNotEmpty)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: VideoPlayerWidget(url: videoUrl, videoUrl: '',),
                          ),
                        if (imageUrl.isEmpty && content.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(content),
                          ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("$likes likes"),
                              IconButton(
                                icon: Icon(Icons.thumb_up),
                                onPressed: () => likePost(
                                  postId,
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                                  FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

class RewardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rewards"),
        backgroundColor: Color(0xFF2196F3),
      ),
      body: Center(
        child: Text(
          "Rewards Coming Soon!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
