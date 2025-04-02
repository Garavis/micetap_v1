import 'package:flutter/material.dart';

PreferredSizeWidget customAppBar(String titleText) {
  return AppBar(
    backgroundColor: Colors.blue,
    automaticallyImplyLeading: false,
    leadingWidth: 20,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/MICETAPBLANCO.png',
          height: 30,
        ),
        const SizedBox(width: 10),
        Text(
          titleText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
                    shadows: [
              Shadow(
                offset: Offset(2, 2), // Posición de la sombra
                blurRadius: 4.0,       // Desenfoque
                color: Colors.black54, // Color de la sombra
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
