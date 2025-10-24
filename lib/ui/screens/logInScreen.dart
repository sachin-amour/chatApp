import 'package:amour_chat/ui/widgets/sTextfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class logInScreen extends StatefulWidget {
  @override
  State<logInScreen> createState() => _logInScreenState();
}

class _logInScreenState extends State<logInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _build());
  }

  Widget _build() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: Column(children: [_header(),
          Container(height: 100,width: 100,
              child: Image.asset("assets/images/chat.png")),
          _loginForm()]),
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
  Widget _loginForm(){
    return Container(
      height: MediaQuery.of(context).size.height*0.40,
      margin: EdgeInsets.symmetric(vertical:MediaQuery.of(context).size.height*0.05),
      child: Form(child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40,),
          customTextField( hintText: " Enter your Email",),
          SizedBox(height: 20,),
          customTextField( hintText: " Enter your Password",),
        ],
      ))

    );
  }
}
