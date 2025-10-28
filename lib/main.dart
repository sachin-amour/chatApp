import 'package:amour_chat/firebase_options.dart';
import 'package:amour_chat/service/alert_service.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:amour_chat/service/database_service.dart';
import 'package:amour_chat/service/firestore_service.dart';
import 'package:amour_chat/service/media_service.dart';
import 'package:amour_chat/service/navigation_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await register_service();
  runApp(amour_chat());
}

Future<void> register_service() async {
  final GetIt getIt = GetIt.instance;
  getIt.registerSingleton<Authservice>(Authservice());
  getIt.registerSingleton<NavigattionService>(NavigattionService());
  getIt.registerSingleton<AlertService>(AlertService());
  getIt.registerSingleton<MediaService>(MediaService());
  getIt.registerSingleton<CloudinaryStorageService>(CloudinaryStorageService());
  getIt.registerSingleton<FirestoreService>(FirestoreService());
}

class amour_chat extends StatelessWidget {
  final GetIt _getIt = GetIt.instance;
  late NavigattionService _navigationService;
  late Authservice _authservice;

  amour_chat({super.key}) {
    _navigationService = _getIt.get<NavigattionService>();
    _authservice = _getIt.get<Authservice>();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        navigatorKey: _navigationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Colors.teal.shade700,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
        initialRoute: _authservice.user != null ? "/home" : "/login",
        routes: _navigationService.routes,
      ),
    );
  }
}