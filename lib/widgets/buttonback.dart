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
            // Verificar si podemos hacer pop (regresar)
            if (Navigator.canPop(context)) {
              // Simplemente regresar a la pantalla anterior
              Navigator.pop(context);
            } else {
              // Si no podemos hacer pop, navegar a la ruta de inicio
              // y limpiar cualquier ruta anterior
              Navigator.pushNamedAndRemoveUntil(
                context,
                route,
                (route) => false,
              );
            }
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}
