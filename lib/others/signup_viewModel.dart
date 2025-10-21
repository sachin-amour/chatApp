import 'dart:developer';
import 'dart:io';

import 'package:amour_chat/enums/enums.dart';
import 'package:amour_chat/others/base_viewmodel.dart';
import 'package:amour_chat/others/user_model.dart';
import 'package:amour_chat/ui/services/authServices.dart';
import 'package:amour_chat/ui/services/dbServices.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupViewmodel extends baseViewModel {
  final AuthService _auth;
  final DatabaseService _db;

  SignupViewmodel(this._auth,this._db);

  String _name = "";
  String _email = "";
  String _password = "";
  String _confirmPassword = "";

  void setName(String value) {
    _name = value;
    notifyListeners();

    log("Name: $_name");
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();

    log("Email: $_email");
  }

  setPassword(String value) {
    _password = value;
    notifyListeners();

    log("Password: $_password");
  }

  setConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();

    log("Confirm Password: $_confirmPassword");
  }

  signup() async {
    setstate(ViewState.loading);
    try {
      final res = await _auth.signup(_email, _password);
      if (res != null) {
        UserModel user = UserModel(
          uid: res.uid,
          name: _name,
          email: _email,
          imageUrl: "",
        );

        await _db.saveUser(user.toMap());
      }
      if (_password != _confirmPassword) {
        throw Exception("The password do not match");

      }

    } on FirebaseAuthException catch (e) {
      setstate(ViewState.idle);
      log(e.toString());

      rethrow;
    } catch (e) {
      setstate(ViewState.idle);
      log(e.toString());
      rethrow;
    }
  }
}
