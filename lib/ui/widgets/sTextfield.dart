import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../myconstent/colors.dart';

class customTextField extends StatelessWidget {
  const customTextField({
    super.key,
    required this.hintText,
    required this.height,
    required this.validationRegEx,
    this.obscureText = false,
    required this.onSaved,
  });
  final String? hintText;
  final double height;
  final RegExp validationRegEx;
  final bool obscureText;
  final void Function(String?) onSaved;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        obscureText: obscureText,
        onSaved: onSaved,
        validator: (value) {
          if (value != null && validationRegEx.hasMatch(value)) {
            return null;
          }
          return "Enter a valid ${hintText!.toLowerCase()}";
        },
        style: TextStyle(fontSize: 18),
        decoration: InputDecoration(
          filled: true,
          fillColor: gray,
          hintText: hintText,

          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),

          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
