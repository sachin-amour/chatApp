import 'package:amour_chat/myconstent/consts.dart';
import 'package:amour_chat/service/alert_service.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:amour_chat/service/navigation_service.dart';
import 'package:amour_chat/ui/widgets/sTextfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class logInScreen extends StatefulWidget {
  @override
  State<logInScreen> createState() => _logInScreenState();
}

class _logInScreenState extends State<logInScreen> {
  final GetIt _getIt = GetIt.instance;
  final GlobalKey<FormState>_loginFromKey= GlobalKey();
  late NavigattionService _navigationService;
  late Authservice _authservice;
  late AlertService _alertService;
  String? email,password;

  @override
  void initState(){
    super.initState();
    _authservice=_getIt.get<Authservice>();
    _navigationService=_getIt.get<NavigattionService>();
    _alertService=_getIt.get<AlertService>();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _build());
  }

  Widget _build() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: Column(
          children: [
            _header(),
            Container(
              height: 200,
              width: 200,
              child: Image.asset("assets/images/login.png"),
            ),
            _loginForm(),
            _signUp(),
          ],
        ),
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
            " Hi, Welcome back !",
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            "Hello again, you've been missed!",
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

  Widget _loginForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      child: Form(
        key: _loginFromKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            customTextField(
              hintText: "Email",
              height: MediaQuery.of(context).size.height * 0.1,
              validationRegEx: EMAIL_VALIDATION_REGEX,
              onSaved: (value){
                setState(() {
                  email= value;
                });
              },
            ),

            customTextField(
              hintText: "Password",
              height: MediaQuery.of(context).size.height * 0.1,
              validationRegEx: PASSWORD_VALIDATION_REGEX,
              obscureText: true,
              onSaved: (value){
                setState(() {
                  password= value;
                });
              },
            ),
            _loginBtn(),
          ],
        ),
      ),
    );
  }
  Widget _loginBtn(){
    return SizedBox( width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height*0.06,
        child: MaterialButton(elevation: 1,shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),),onPressed: ()async{
          if(_loginFromKey.currentState?.validate()??false){
             _loginFromKey.currentState?.save();
             bool result =await _authservice.login(email!, password!);
              if(result){
                _navigationService.pushReplacementNamed("/home");

              }else{
                _alertService.showToast(message: "Invalid email or password",icon: Icons.error);
              }
          }

        },child: Text("Login",style: TextStyle(color: Colors.black54,fontSize: 20),),color: Colors.tealAccent,));
  }
  Widget _signUp(){
    return Expanded(child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
     children: [
       Text("Don't have an account?",style: TextStyle(color: Colors.grey,fontSize: 16)),
       TextButton(onPressed: (){}, child: Text("Sign Up",style: TextStyle(color: Colors.teal,fontSize: 20)))
     ],
    ));
  }
}
