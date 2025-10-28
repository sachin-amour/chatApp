import 'package:amour_chat/ui/screens/homeScreen.dart';
import 'package:amour_chat/ui/screens/logInScreen.dart';
import 'package:amour_chat/ui/screens/search_screen.dart';
import 'package:amour_chat/ui/screens/signUpScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NavigattionService {
  late GlobalKey<NavigatorState> _navigatorKey;
  final Map<String, Widget Function(BuildContext)> _routes = {
    "/login": (context) => logInScreen(),
    "/home": (context) => homeScreen(),
    "/signup": (context) => SignupScreen(),
    "/search": (context) => const SearchScreen(),
  };

  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;
  Map<String, Widget Function(BuildContext)> get routes => _routes;

  NavigattionService() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  void push(MaterialPageRoute route) {
    _navigatorKey.currentState?.push(route);
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void goBack() {
    _navigatorKey.currentState?.pop();
  }
}