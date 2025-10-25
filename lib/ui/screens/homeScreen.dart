import 'package:amour_chat/service/alert_service.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:amour_chat/service/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class homeScreen extends StatefulWidget{
  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  final GetIt _getIt = GetIt.instance;
  late NavigattionService _navigationService;
  late Authservice _authservice;
  late AlertService _alertService;
  @override
  void initState() {
    super.initState();
    _authservice = _getIt.get<Authservice>();
    _navigationService = _getIt.get<NavigattionService>();
    _alertService = _getIt.get<AlertService>();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Amour Chat"),
        actions: [
          IconButton(onPressed: ()async{
            bool result= await _authservice.logout();
            if(result){
              _alertService.showToast(message: "Logged out successfully");
              _navigationService.pushReplacementNamed("/login");
            }
          }, icon: Icon(Icons.logout))
        ],
      ),

    );

  }
}