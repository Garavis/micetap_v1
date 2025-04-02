
import 'package:flutter/material.dart';

class textfieldcampos extends StatelessWidget {
  final String text;
  final bool isPassword;
  const textfieldcampos({
    super.key,
    required TextEditingController Controller,
    required this.text,
    this.isPassword = false,

  }) : Controller = Controller;

  final TextEditingController Controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: Controller,
      decoration: InputDecoration(
        labelText: text,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      obscureText: isPassword,
    );
  }
}