import 'package:amour_chat/myconstent/colors.dart';
import 'package:amour_chat/others/extension.dart';
import 'package:amour_chat/others/login_viewModel.dart';
import 'package:amour_chat/ui/sTextfield.dart';
import 'package:amour_chat/ui/screens/homeScreen.dart';
import 'package:amour_chat/ui/screens/singupScreen.dart';
import 'package:amour_chat/ui/services/authServices.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class logInScreen extends StatelessWidget {
  final bool loading=false;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewmodel>(
      create: (context) => LoginViewmodel(AuthService()),
        child: Consumer<LoginViewmodel>(builder: (context, model,_) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Text(
                "Login",
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Please login to your account",
              style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: 380,
                child: customTextField(
                  onChanged:model.setEmail,
                  hintText: "Enter Email",
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: 380,
                child: customTextField(
                  onChanged:model.setPassword,
                  hintText: "Enter Password",
                ),
              ),
            ),

            SizedBox(height: 38),
            SizedBox(
              width: 380,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await model.login();
                    context.ShowSnackBar("user successfully logged in");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>HomeScreen()),
                    );

                  } catch (e) {
                  context.ShowSnackBar(e.toString());
                }},
                child: loading?Center(child: CircularProgressIndicator()):Text(
                  'Login',
                  style: TextStyle(color: Colors.white, fontSize: 23),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: primary),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  " Don't have account?  ",
                  style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade600),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => signupScreen()),
                    );
                  },
                  child: Text(
                    "Sign up",
                    style: TextStyle(
                      fontSize: 17.sp,
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
        }),
    );
  }
}
