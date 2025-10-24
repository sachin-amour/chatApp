import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../myconstent/colors.dart';


class customTextField extends StatelessWidget{
  const customTextField({super.key,this.hintText,required this.height});
  final String? hintText;
  final double height;


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(

          style: TextStyle(fontSize: 18),
          decoration: InputDecoration(
          filled: true,
          fillColor: gray,
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14,color: Colors.grey.shade600),

          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide.none,


          )

        ) ),
    );

  }

}