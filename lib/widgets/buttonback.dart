import 'package:flutter/material.dart';

class FloatingBackButton extends StatelessWidget {
  final String route;

  const FloatingBackButton({super.key, this.route = '/'});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, route);
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}
