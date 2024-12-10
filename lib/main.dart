import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportmate/screens/FeedScreen.dart';
import 'package:sportmate/screens/RegisterScreen.dart';
import 'package:sportmate/screens/LoginScreen.dart';
import 'package:sportmate/screens/home_screen.dart';
import 'package:sportmate/screens/splashscreen.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Mobile Ads
  MobileAds.instance.initialize();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set Firebase Auth persistence
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

    // Activate Firebase App Check
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('6LcKyXoqAAAAAGabyupoIlyRmcv7rW-o0EGvnequ'),
    );
  } catch (error) {
    print('Error initializing Firebase: $error');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportMate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Material 3 design
      ),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // Updated to use dynamic authentication wrapper
      routes: {
        '/home': (context) => HomeScreen(),
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/feed': (context) => FeedScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        // Redirect to HomeScreen if logged in, otherwise LoginScreen
        if (snapshot.hasData) {
          return FeedScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
