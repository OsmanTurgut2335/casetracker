import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'introScreen.dart'; // Import IntroScreen
import 'package:email_validator/email_validator.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference =
  FirebaseDatabase(
    databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),
            SizedBox(height: 25),

            ElevatedButton(
              onPressed: () async {
                // Validate the email address using EmailValidator
                if (!EmailValidator.validate(_emailController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Invalid email format. Please enter a valid email address.'),
                    ),
                  );
                  return; // Stop further processing if the email is not valid
                }

                try {
                  // Try to sign in the user
                  await _auth.signInWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );

                  // Check if the user is not null (exists)
                  if (_auth.currentUser != null) {
                    // If the sign-in is successful and the user exists, navigate to the IntroScreen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } else {
                    // If the user does not exist, show an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'User does not exist. Please check your credentials.'),
                      ),
                    );
                  }
                } catch (e) {
                  // Handle login failure
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Login failed. Please check your credentials.'),
                    ),
                  );
                }
              },
              child: Text('Login'),
            ),

            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Try to sign up the user
                  await _auth.createUserWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );

                  // Send email verification to the user
                  await _auth.currentUser!.sendEmailVerification();

                  // Update Firestore usernames collection
                  await _firestore.collection('usernames').doc('usernames').update({
                    'userList': FieldValue.arrayUnion([
                      {'userid': _auth.currentUser!.uid, 'username': ''}
                    ])
                  });

                  // Create user in the Realtime Database under _databaseReference.child('users')
                  _databaseReference.child('users').child(_auth.currentUser!.uid).set({
                    'email': _auth.currentUser!.email,
                    // Add any other user-related information you want to store
                  });

                  // Show a snackbar on successful user creation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'User created successfully. Please check your email for verification.',
                      ),
                    ),
                  );
                } catch (e) {
                  // Print the error to the console for debugging
                  print(e);

                  // Handle sign-up failure
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign up failed. Please try again.'),
                    ),
                  );
                }
              }
              ,
                child: Text('Sign Up'),
            ),

            SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                try {
                  // Send a password reset email to the user's email address
                  await _auth.sendPasswordResetEmail(email: _emailController.text);

                  // Show a snackbar indicating that the password reset email has been sent
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent. Check your email.'),
                    ),
                  );
                } catch (e) {
                  // Handle password reset failure
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset failed. Please try again.'),
                    ),
                  );
                }
              },
              child: Text('Şifremi Unuttum'),
            ),
          ],
        ),
      ),
    );
  }
}