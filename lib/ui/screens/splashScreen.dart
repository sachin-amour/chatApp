import 'dart:async';

import 'package:amour_chat/myconstent/string.dart';
import 'package:amour_chat/ui/wrapper/wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class splashScreen extends StatefulWidget{


  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  Timer? _timer;
  @override
  void  initState(){
  super.initState();
  _timer=Timer(const Duration(seconds: 2), (){
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Wrapper()));
  });
  }
  @override
  void dispose(){
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(logo),
      )

    );

  }
}