import 'package:amour_chat/ui/screens/homeScreen.dart';
import 'package:amour_chat/ui/screens/logInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user != null) {
            return const HomeScreen();
          }
          return logInScreen();
        }
    );
  }
}