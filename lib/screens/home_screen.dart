import 'package:flutter/material.dart';
import 'package:sportmate/screens/LoginScreen.dart';
import 'package:sportmate/screens/RegisterScreen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SportsMate'),
        centerTitle: true,
        backgroundColor: Color(0xFF2196F3), // Blue color for sports theme
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3), // Blue gradient for sports theme
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/sports_logo.png', // Add a sports-themed logo
                width: 120.0,
                height: 120.0,
              ),
              SizedBox(height: 32.0),
              Text(
                'Welcome to Mate!',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Use white text for better visibility on blue background
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.0),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: const Color(0xFF1976D2), minimumSize: Size(double.infinity, 56.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ), // Use white text for better visibility
                ),
                icon: Icon(Icons.app_registration),
                label: Text('Register'),
              ),
              SizedBox(height: 16.0),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1976D2), minimumSize: Size(double.infinity, 56.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ), // Darker blue for outlined button
                  side: BorderSide(color: Color(0xFF1976D2)), // Darker blue for button border
                ),
                icon: Icon(Icons.login, color: Color(0xFF1976D2)), // Darker blue for icon
                label: Text('Login', style: TextStyle(color: Color(0xFF1976D2))), // Darker blue for text
              ),
            ],
          ),
        ),
      ),
    );
  }
}