import 'package:amour_chat/myconstent/chat_tile.dart';
import 'package:amour_chat/service/alert_service.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:amour_chat/service/firestore_service.dart';
import 'package:amour_chat/service/navigation_service.dart';
import 'package:amour_chat/ui/screens/chatScreen.dart';
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
  late FirestoreService _firestoreService;
  @override
  void initState() {
    super.initState();
    _authservice = _getIt.get<Authservice>();
    _navigationService = _getIt.get<NavigattionService>();
    _alertService = _getIt.get<AlertService>();
    _firestoreService = _getIt.get<FirestoreService>();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text(
          "Amour Chat",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                bool result = await _authservice.logout();
                if (result) {
                  _alertService.showToast(message: "Logged out successfully");
                  _navigationService.pushReplacementNamed("/login");
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white)
          )
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: _build(),
    );
  }

  Widget _build(){
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: _chatList(),
    ),
    );
  }
  Widget _chatList(){
    return StreamBuilder(stream: _firestoreService.getUserProfiles(), builder: (context,snapshot){
      if(snapshot.hasError){
        return const Center(
          child: Text("unable to load data"),
        );
      }
      if(snapshot.hasData && snapshot.data!=null){
        final users= snapshot.data!.docs;
        return ListView.builder(itemCount:users.length ,itemBuilder: (context,index){
          final userProfile= users[index].data();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ChatTile(userProfile: userProfile, onTap: ()async{
              final chatExists= await _firestoreService.CheckChatExists(
               _authservice.user!.uid,
                userProfile.uid!,
              );
              if(!chatExists){
                await _firestoreService.createChat(
                  _authservice.user!.uid,
                  userProfile.uid!,
                );

              }
              _navigationService.push(MaterialPageRoute(builder: (context)=>chatScreen(userProfile: userProfile,)));
            }),
          );
        });
      }
      return const Center(
        child: CircularProgressIndicator(),
      );
    });
  }
}