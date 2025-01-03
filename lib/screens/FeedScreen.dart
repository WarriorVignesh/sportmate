import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sportmate/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sportmate/distance_util.dart';
import 'package:sportmate/screens/PostDetailScreen.dart';
import 'package:sportmate/screens/profilescreen.dart';
import 'package:sportmate/video_player_widget.dart';
import 'create_post_screen.dart';

import 'package:geolocator/geolocator.dart';


class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
   Future<double> _getPostDistance(double eventLat, double eventLon) async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return DistanceUtil.calculateDistance(
      position.latitude, position.longitude, eventLat, eventLon,
    );
  }

  Stream<List<DocumentSnapshot>> getMergedPosts() {
    var postsStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
    var teamPostsStream = FirebaseFirestore.instance
        .collection('teamPosts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);

    return Rx.combineLatest2<List<DocumentSnapshot>, List<DocumentSnapshot>, List<DocumentSnapshot>>(
      postsStream,
      teamPostsStream,
      (posts, teamPosts) => [...posts, ...teamPosts]
        ..sort((a, b) {
          var aTime = a['createdAt']?.toDate() ?? DateTime.now();
          var bTime = b['createdAt']?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        }),
    );
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
    body: PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      children: [
        // Feed Page
        buildFeedPage(),
        // Marketplace Page
        MarketplacePage(),
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentPage,
      onTap: (index) {
        _pageController.jumpToPage(index);
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.feed),
          label: 'Feeds',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Marketplace',
        ),
      ],
    ),
  );
}

Widget buildFeedPage() {
  return Container(
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
    child: StreamBuilder<List<DocumentSnapshot>>(
      stream: getMergedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading posts",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No posts available",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var post = snapshot.data![index];
            var data = post.data() as Map<String, dynamic>;
            String postId = post.id;
            String username = data['username'] ?? 'Anonymous';
            int likes = data['likes'] ?? 0;
            String imageUrl = data['fileUrl'] ?? '';
            String videoUrl = data['videoUrl'] ?? '';
            double eventLat = data['latitude'] ?? 0.0;
            double eventLon = data['longitude'] ?? 0.0;

            return FutureBuilder<double>(
              future: _getPostDistance(eventLat, eventLon),
              builder: (context, distanceSnapshot) {
                String distanceText = distanceSnapshot.hasData
                    ? '${distanceSnapshot.data!.toStringAsFixed(2)} km away'
                    : 'Calculating distance...';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PostDetailScreen(postId: postId,distance: distanceText,)),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16.0),
                              ),
                              SizedBox(height: 5),
                              Text(
                                distanceText,
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (imageUrl.isNotEmpty)
                          Image.network(imageUrl, fit: BoxFit.cover),
                        if (videoUrl.isNotEmpty)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: VideoPlayerWidget(
                              url: videoUrl,
                              videoUrl: '',
                            ),
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
                                    FirebaseAuth.instance.currentUser?.displayName ??
                                        'Unknown',
                                  ),
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ),
  );
}

}


class RewardScreen extends StatelessWidget {
  final int userPoints = 120; // Example user points
  final List<Map<String, dynamic>> rewards = [
    {
      'title': '10% Discount Coupon',
      'pointsRequired': 100,
      'description': 'Get 10% off on your next purchase.',
    },
    {
      'title': 'Free Shipping',
      'pointsRequired': 200,
      'description': 'Enjoy free shipping on your next order.',
    },
    {
      'title': 'Gift Card -',
      'pointsRequired': 300,
      'description': 'Redeem this gift card for any purchase.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rewards'),
        centerTitle: true,
        backgroundColor: Color(0xFF2196F3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Points Display
            Text(
              'Your Points: $userPoints',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Rewards List
            Text(
              'Available Rewards:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rewards[index]['title'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),
                          Text(rewards[index]['description']),
                          SizedBox(height: 8.0),
                          Text('Points Required: ${rewards[index]['pointsRequired']}'),
                          SizedBox(height: 10.0),
                          ElevatedButton(
                            onPressed: userPoints >= rewards[index]['pointsRequired']
                                ? () => _redeemReward(context, rewards[index])
                                : null,
                            child: Text('Redeem'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: userPoints >= rewards[index]['pointsRequired']
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redeemReward(BuildContext context, Map<String, dynamic> reward) {
    // Logic for redeeming the reward (e.g., deduct points and show confirmation)
    // This is just a placeholder for demonstration.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem Reward'),
        content: Text('You have redeemed "${reward['title']}"!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Here you would typically deduct points from the user account
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}


class MarketplacePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration : BoxDecoration(color : Colors.white),
      child : Column(children : [
         Padding(padding : EdgeInsets.all(16.0), child : Row(children : [
           Expanded(child : Text("Marketplace", style : TextStyle(fontSize : 24 , fontWeight : FontWeight.bold))),
           ElevatedButton(onPressed : () { 
             Navigator.push(context , MaterialPageRoute(builder : (context) => AddProductScreen()));
           }, child : Text('Add Product')),
         ],),),
         Expanded(child : StreamBuilder<List<DocumentSnapshot>>(
           stream : FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending : true).snapshots().map((snapshot) => snapshot.docs),
           builder : (context, snapshot){
             if(snapshot.connectionState == ConnectionState.waiting){
               return Center(child : CircularProgressIndicator());
             }
             if(snapshot.hasError){
               return Center(child : Text("Error loading products"));
             }
             if(!snapshot.hasData || snapshot.data!.isEmpty){
               return Center(child : Text("No products available"));
             }

             return ListView.builder(itemCount : snapshot.data!.length, itemBuilder : (context, index){
               var product = snapshot.data![index];
               var data = product.data() as Map<String, dynamic>;
               String productId = product.id;
               String productName = data['name'] ?? 'Unnamed Product';
               double productPrice = data['price'] ?? 0.0;
               String imageUrl = data['imageUrl'] ?? '';
               String contactDetails = data['contactDetails'] ?? '';

               return Card(
                 margin : EdgeInsets.all(10.0),
                 child : Column(children : [
                   ListTile(title : Text(productName), subtitle : Text("\$${productPrice.toString()}")),
                   if(imageUrl.isNotEmpty)
                     Image.network(imageUrl, fit : BoxFit.cover),
                   ButtonBar(children : [
                     TextButton(onPressed : () {/* Add to cart logic */}, child : Text("Add to Cart")),
                     TextButton(onPressed : () {
                       // View details logic
                       showDialog(context: context, builder:(context)=>AlertDialog(title:
                         Text(productName), content:
                         Column(mainAxisSize:
                         MainAxisSize.min, children:[
                           Image.network(imageUrl), 
                           SizedBox(height:
                           10,), 
                           Text("Price:\$${productPrice.toString()}"), 
                           SizedBox(height:
                           10,), 
                           Text("Contact:\n$contactDetails", style:
                           TextStyle(fontWeight:
                           FontWeight.bold)), 
                         ]), actions:[TextButton(onPressed:
                         ()=>Navigator.of(context).pop(), child:
                         Text("Close"))],));
                     }, child :
                       Text("View Details")),
                   ]),
                 ]),
               );
             });
           },
         )),
       ]),
     );
   }
}

class AddProductScreen extends StatefulWidget {
   @override
   _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productPriceController = TextEditingController();
  final TextEditingController contactDetailsController = TextEditingController();

  File? _selectedFile;
  String? _selectedFileUrl;
  String? _fileType; // "image" or "video"
  bool _isLoading = false;

  final CloudinaryService cloudinaryService = CloudinaryService(
    cloudName: 'djusnuweg',
    apiKey: '933488682224341',
    apiSecret: 'JA13vW11QltMLD9clvAYPuOHScA',
    uploadPreset: 'sportsmate',
  );

  Future<void> _pickMedia({String type = 'image'}) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (type == 'image') {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else if (type == 'video') {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        String? uploadedUrl = await cloudinaryService.uploadMedia(pickedFile.path);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading $type: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addProduct() async {
    String name = productNameController.text.trim();
    String priceStr = productPriceController.text.trim();
    String contactDetails = contactDetailsController.text.trim();

    if (name.isEmpty || priceStr.isEmpty || contactDetails.isEmpty || _selectedFileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and upload an image.')),
      );
      return;
    }

    double price;
    try {
      price = double.parse(priceStr);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid price format.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': price,
        'contactDetails': contactDetails,
        'imageUrl': _selectedFileUrl,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: productNameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: productPriceController,
              decoration: InputDecoration(labelText: 'Product Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: contactDetailsController,
              decoration: InputDecoration(labelText: 'Contact Details'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickMedia(type: 'image'),
              child: Text('Upload Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _addProduct,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
} 