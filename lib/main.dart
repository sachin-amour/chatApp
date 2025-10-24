import 'package:amour_chat/firebase_options.dart';
import 'package:amour_chat/ui/screens/logInScreen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(amour_chat());
}

class amour_chat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) =>
          MaterialApp(debugShowCheckedModeBanner: false,
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            ),

            home:logInScreen(),
          ));
  }
}
