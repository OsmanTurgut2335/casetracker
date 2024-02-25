import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart';
import 'introScreen.dart';
import 'login_screen.dart'; // Import your LoginScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthChecker(), // Use AuthChecker instead of HomeScreen directly
    );
  }
}

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Loading indicator while checking authentication state
        } else {
          if (snapshot.hasData) {
            // User is signed in, show HomeScreen
            return HomeScreen();
          } else {
            // User is not signed in, show LoginScreen
            return LoginScreen();
          }
        }
      },
    );
  }
}
