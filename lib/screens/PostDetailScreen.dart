import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  PostDetailScreen({required this.postId});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late BannerAd _bannerAd;
  late InterstitialAd _interstitialAd;
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Replace with your AdMob unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Replace with your AdMob unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  Future<void> _showInterstitialAd() async {
    if (_isInterstitialAdLoaded) {
      _interstitialAd.show();
      _loadInterstitialAd(); // Reload for the next use
    }
  }

  Future<void> registerForTournament(
      String postId, String userId, String postCreatorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('registrations')
          .add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send notification to the post creator
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': postCreatorId,
        'title': "New Registration",
        'message': "A user has registered for your post.",
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'postId': postId,
          'userId': userId,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration successful!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during registration: $e")),
      );
    }
  }

  Future<void> markInterest(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'interestCount': FieldValue.increment(1),
      });
      // Refresh the screen to show updated interest count
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating interest count: $e")),
      );
    }
  }

  String determineTag(DateTime date) {
    final now = DateTime.now();
    if (date.isBefore(now) && date.isAfter(now.subtract(Duration(days: 1)))) {
      return "Ongoing";
    } else if (date.isBefore(now)) {
      return "Past Completed";
    } else {
      return "Future Upcoming";
    }
  }

  Color getStatusColor(String tag) {
    switch (tag) {
      case "Ongoing": 
        return Colors.green;
      case "Past Completed":
        return Colors.grey;
      case "Future Upcoming":
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Post Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('posts').doc(widget.postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading post details"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Post not found"));
          }

          var post = snapshot.data!.data() as Map<String, dynamic>;
          DateTime? postDate = post['date'] != null
              ? (post['date'] as Timestamp).toDate()
              : null;
          String tag = postDate != null ? determineTag(postDate) : "Date not set";
          int interestCount = post['interestCount'] ?? 0;
          String postCreatorId = post['creatorId'] ?? "";

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                post['posterUrl'] != null && (post['posterUrl'] ).isNotEmpty
                    ? Image.network(
                        post['posterUrl'],
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image, size: 100, color: Colors.grey);
                        },
                      )
                    : Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                SizedBox(height: 10),
                Text(post['title'] ?? "No Title", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                if (postDate != null)
                  Text(
                    "Date: ${DateFormat.yMMMd().add_jm().format(postDate)}",
                    style: TextStyle(fontSize: 16),
                  ),
                Text(
                  "Status: $tag",
                  style: TextStyle(fontSize: 16, color: getStatusColor(tag)),
                ),
                SizedBox(height: 10),
                Text(post['description'] ?? "No description available."),
                SizedBox(height: 10),
                Text("Organizer: ${post['organizer'] ?? "Unknown"}"),
                SizedBox(height: 10),
                Text("Location: ${post['location'] ?? "Not provided"}"),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      child: Text("Mark Interested ($interestCount)"),
                      onPressed: () async {
                        await markInterest(widget.postId);
                      },
                    ),
                    ElevatedButton(
                      child: Text("Register"),
                      onPressed: (currentUser != null && tag != "Past Completed")
                          ? () async {
                              await _showInterstitialAd();
                              await registerForTournament(
                                  widget.postId, currentUser.uid, postCreatorId);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _isBannerAdLoaded
          ? Container(
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            )
          : SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _interstitialAd.dispose();
    super.dispose();
  }
}
