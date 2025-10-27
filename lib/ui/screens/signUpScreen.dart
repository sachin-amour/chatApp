import 'dart:io';

import 'package:amour_chat/model/auth_model.dart';
import 'package:amour_chat/myconstent/consts.dart';
import 'package:amour_chat/service/alert_service.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:amour_chat/service/database_service.dart';
import 'package:amour_chat/service/firestore_service.dart';
import 'package:amour_chat/service/media_service.dart';
import 'package:amour_chat/service/navigation_service.dart';
import 'package:amour_chat/ui/widgets/sTextfield.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _signupFromKey = GlobalKey();
  final GetIt getIt = GetIt.instance;
  late NavigattionService _navigationService;
  late MediaService _mediaService;
  late Authservice _authservice;
  late CloudinaryStorageService _cloudinaryStorageService;
  late FirestoreService _firestoreService;
  late AlertService _alertService;
  bool isloading = false;

  String? email;
  String? name;
  String? password;

  File? selectedImage;
  @override
  void initState() {
    super.initState();
    _mediaService = getIt.get<MediaService>();
    _navigationService = getIt.get<NavigattionService>();
    _authservice = getIt.get<Authservice>();
    _cloudinaryStorageService = getIt.get<CloudinaryStorageService>();
    _firestoreService =getIt.get<FirestoreService>();
    _alertService= getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _build());
  }

  Widget _build() {
    return SafeArea(
      child: Stack(
        children:[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
            child: Column(children: [_header(),
              if(!isloading)_signupForm(),
              if(!isloading)_login(),
              if(isloading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
            ]),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * -0.04,
            right: MediaQuery.of(context).size.width * -0.03,
            child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.55,
                height: MediaQuery.of(context).size.width * 0.55,
                child: Image.asset('assets/images/chatbobles.png')),
          ),
        ]
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            " Let's get started !",
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            "Register below with your details",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signupForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      child: Form(
        key: _signupFromKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _profileImg(),
            SizedBox(height: 20),
            customTextField(
              hintText: "name",
              height: MediaQuery.of(context).size.height * 0.1,
              validationRegEx: NAME_VALIDATION_REGEX,
              onSaved: (value) {
                setState(() {
                  name = value;
                });
              },
            ),

            customTextField(
              hintText: "Email",
              height: MediaQuery.of(context).size.height * 0.1,
              validationRegEx: EMAIL_VALIDATION_REGEX,
              onSaved: (value) {
                setState(() {
                  email = value;
                });
              },
            ),

            customTextField(
              hintText: "Password",
              height: MediaQuery.of(context).size.height * 0.1,
              validationRegEx: PASSWORD_VALIDATION_REGEX,
              obscureText: true,
              onSaved: (value) {
                setState(() {
                  password = value;
                });
              },
            ),
            _signUpBtn(),
          ],
        ),
      ),
    );
  }

  Widget _profileImg() {
    return GestureDetector(
      onTap: () async {
        File? image = await _mediaService.getImageFormGallery();
        if (image != null) {
          setState(() {
            selectedImage = image;
          });
        }
      },
      child: CircleAvatar(
        radius: MediaQuery.of(context).size.width * 0.15,
        backgroundImage: selectedImage != null
            ? FileImage(selectedImage!)
            : NetworkImage(PLACEHOLDER_PFP) as ImageProvider,
      ),
    );
  }

  Widget _signUpBtn() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.06,
      child: MaterialButton(
        elevation: 1,
        color: Colors.teal.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () async {
          setState(() {
            isloading=true;
          });
          try {
            if ((_signupFromKey.currentState?.validate() ?? false) &&
                selectedImage != null) {
              _signupFromKey.currentState?.save();
              bool result = await _authservice.signup(email!, password!);
              if (result) {
                String? pfpURL = await _cloudinaryStorageService.uploadUserPfp(
                  file: selectedImage!,
                  uid: _authservice.user!.uid,
                );
                if (pfpURL != null) {
                  await _firestoreService.creatUserProfile(
                    userProfile: UserProfile(
                    uid: _authservice.user!.uid,
                    name: name!,
                    pfpURL: pfpURL,
                    ),
                  );
                  _alertService.showToast(message: "User registered successfully!",icon: Icons.check);

                  _navigationService.goBack();
                  _navigationService.pushReplacementNamed("/home");

                } else {
                  throw Exception("unable to upload profile picture");
                }
              } else {
                throw Exception("unable to register user");
                }
            }
          } catch (e) {
            print(e);
            _alertService.showToast(message: "Failed to register, please try again",icon: Icons.error);
          }
          setState(() {
            isloading= false;
          });
        },
        child: Text(
          "Sign Up",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }

  Widget _login() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account?",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          TextButton(
            onPressed: () {
              _navigationService.goBack();
            },
            child: Text(
              "Login",
              style: TextStyle(color: Colors.teal, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
