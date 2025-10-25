
import 'package:firebase_auth/firebase_auth.dart';
class Authservice{
  final FirebaseAuth _firebaseAuth =FirebaseAuth.instance;
  User? _user;
  User? get user {
    return _user;
  }
  Authservice(){}
    Future<bool>login(String email,String password) async {
    try{
      final credential= await  _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user!=null){
        _user=credential.user;
        return true;
      }
    }
    catch(e){
      print(e);
    }
    return false;

    }

  }
