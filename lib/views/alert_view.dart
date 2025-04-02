import 'package:flutter/material.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({Key? key}) : super(key: key);

  @override
  _AlertsViewState createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  // Lista de ejemplo de alertas
  final List<Map<String, dynamic>> _alerts = [
    {'type': 'warning', 'message': 'Consumo por encima de la media'},
    {'type': 'critical', 'message': 'Consumo crítico'},
    {'type': 'warning', 'message': 'Consumo por encima de la media'},
    {'type': 'critical', 'message': 'Consumo crítico'},
    {'type': 'critical', 'message': 'Consumo crítico'},
    {'type': 'excellent', 'message': 'Excelente'},
  ];

  void _exportar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando informe...')),
    );
  }

    void _vaciar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vaciando...')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('ALERTAS'),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Historico de Alertas',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              
            ),
            const SizedBox(height: 15),
            // Lista de alertas
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    return _buildAlertItemCard(_alerts[index]);
                  },
                ),
                
              ),
            ),
            
            // Botones de acción
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Lógica para exportar
                        _exportar();
                      },
                      // Estilo del botón
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: Text('Exportar', 
                      style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      )),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Lógica para vaciar
                        _vaciar();
                        setState(() {
                          _alerts.clear();
                        });
                      },
                      // Estilo del botón
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: Text('Vaciar', 
                      style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      )),
                    ),
                  ),
                ),
              ],
            ),
            
            // Botón de retroceso
            const SizedBox(height: 20),
            const FloatingBackButton(route: '/home'),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItemCard(Map<String, dynamic> alert) {
    IconData icon;
    Color iconColor;
    
    switch (alert['type']) {
      case 'warning':
        icon = Icons.warning_amber_outlined;
        iconColor = Colors.orange;
        break;
      case 'critical':
        icon = Icons.close;
        iconColor = Colors.red;
        break;
      case 'excellent':
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.blue;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.zero,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                alert['message'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}