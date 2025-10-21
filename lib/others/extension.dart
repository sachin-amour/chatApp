import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension ConetextExtension on BuildContext{
  ShowSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}