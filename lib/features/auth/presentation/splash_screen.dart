import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          final user = snapshot.data;
          if (user != null) {
            Future.microtask(
                () => Navigator.pushReplacementNamed(context, '/tasks'));
          } else {
            Future.microtask(
                () => Navigator.pushReplacementNamed(context, '/onboarding'));
          }
          return const SizedBox.shrink();
        }
      },
    );
  }
}
