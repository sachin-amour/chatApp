import 'dart:developer';
import 'package:amour_chat/enums/enums.dart';
import 'package:amour_chat/others/base_viewmodel.dart';
import 'package:amour_chat/ui/services/authServices.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginViewmodel extends baseViewModel {
  final AuthService _auth;

  LoginViewmodel(this._auth);

  String _email = '';
  String _password = '';

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

  login() async {
    setstate(ViewState.loading);
    try {
      await _auth.login(_email, _password);
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