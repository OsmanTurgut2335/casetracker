import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/provider/providers.dart';
import 'config/firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart'; // Import your LoginScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(
    ProviderScope(  // Wrap MyApp with ProviderScope
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthChecker(), // Use AuthChecker instead of HomeScreen directly
    );
  }
}

class AuthChecker extends ConsumerWidget  {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Loading indicator while checking authentication state
        } else {
          if (snapshot.hasData) {
            // User is signed in, show HomeScreen
            return HomeScreen(firestoreRepository: firestoreRepository,);
          } else {
            // User is not signed in, show LoginScreen
            return const LoginScreen();
          }
        }
      },
    );
  }
}
