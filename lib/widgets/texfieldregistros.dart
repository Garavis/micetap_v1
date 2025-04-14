import 'package:flutter/material.dart';

class textfieldcampos extends StatefulWidget {
  final String text;
  final bool isPassword;
  final TextEditingController Controller;

  const textfieldcampos({
    Key? key,
    required this.Controller,
    required this.text,
    this.isPassword = false,
  }) : super(key: key);

  @override
  _textfieldcamposState createState() => _textfieldcamposState();
}

class _textfieldcamposState extends State<textfieldcampos> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.Controller,
      obscureText: widget.isPassword ? _obscureText : false,
      decoration: InputDecoration(
        labelText: widget.text,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
