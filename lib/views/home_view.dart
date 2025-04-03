import 'package:flutter/material.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final double _consumption = 0.00000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('MICETAP'),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grid de opciones
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85, // Proporción más cuadrada
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMenuCard(
                    title: 'Historial',
                    imagePath: 'assets/images/home/history.png',
                    onTap: () {
                      Navigator.pushNamed(context, '/history');
                    },
                  ),    
                  _buildMenuCard(
                    title: 'Alertas',
                    imagePath: 'assets/images/home/alert.png',
                    onTap: () {
                      Navigator.pushNamed(context, '/alerts');
                    },
                  ),
                  _buildMenuCard(
                    title: 'Sugerencias',
                    imagePath: 'assets/images/home/suge.png',
                    onTap: () {
                      Navigator.pushNamed(context, '/suggestions');
                    },
                  ),
                  _buildMenuCard(
                    title: 'Configuración',
                    imagePath: 'assets/images/home/config.png',
                    onTap: () {
                      Navigator.pushNamed(context, '/config');
                    },
                  ),
                ],
              ),
            ),
            
            // Indicador de consumo
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'Consumo Actual kWh:',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _consumption.toStringAsFixed(5).padLeft(8, '0'),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 70),
                  Text(
                    '©Powered by: Garavis A, Paz H',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Botón de retroceso
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.grey[50], // Color de fondo muy claro como en tu diseño
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // Contenedor de imagen que ocupa la mayor parte de la tarjeta
            Expanded(
              flex: 4, // Damos más espacio a la imagen
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain, // Ajusta la imagen para que se vea completa
                    width: double.infinity, // Ocupa todo el ancho disponible
                  ),
                ),
              ),
            ),
            // Texto en la parte inferior
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}