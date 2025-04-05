import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({Key? key}) : super(key: key);

  @override
  _AlertsViewState createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  String? deviceId;
  bool _isLoading = true;
  String? _debugError;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    setState(() {
      _isLoading = true;
      _debugError = null;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _debugError = "No hay usuario autenticado";
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        final fetchedId = doc.data()?['deviceId'];
        print("🔎 deviceId desde usuario: $fetchedId");
        print("🔎 deviceId tipo: ${fetchedId.runtimeType}");
        
        if (fetchedId != null) {
          String formattedId = fetchedId.toString().trim();
          print("🔎 deviceId formateado: '$formattedId'");
          
          // Verificar si el formato es correcto
          setState(() {
            deviceId = formattedId;
            _isLoading = false;
          });
          
          // Verificar si existen documentos con ese deviceId
          _checkAlertasByDeviceId(formattedId);
        } else {
          setState(() {
            _debugError = "deviceId es null";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _debugError = "Usuario no existe en Firestore";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _debugError = "Error al cargar deviceId: $e";
        _isLoading = false;
      });
      print("❌ Error: $e");
    }
  }

  Future<void> _checkAlertasByDeviceId(String id) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('alertas')
          .get();
          
      print("🔍 Total de alertas (sin filtro): ${snapshot.docs.length}");
      
      // Verificar manualmente si hay coincidencias
      int matches = 0;
      for (var doc in snapshot.docs) {
        String alertDeviceId = doc.data()['deviceId']?.toString() ?? '';
        print("🔍 Comparando: '$alertDeviceId' con '$id'");
        if (alertDeviceId == id) {
          matches++;
        }
      }
      print("🔍 Coincidencias encontradas: $matches");
      
      // Ahora intentar con el filtro where
      final filteredSnapshot = await FirebaseFirestore.instance
          .collection('alertas')
          .where('deviceId', isEqualTo: id)
          .get();
      
      print("🔍 Alertas con filtro where: ${filteredSnapshot.docs.length}");
      
      if (filteredSnapshot.docs.isEmpty && matches > 0) {
        setState(() {
          _debugError = "El filtro where no funciona pero hay coincidencias";
        });
      }
    } catch (e) {
      print("❌ Error al verificar alertas: $e");
    }
  }

  void _exportar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando informe...')),
    );
  }

  void _vaciar() async {
    if (deviceId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('alertas')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alertas eliminadas')),
    );
  }

  Widget _buildAlertList(String deviceId) {
    return Column(
      children: [
        if (_debugError != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              color: Colors.red[100],
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Debug: $_debugError",
                style: TextStyle(color: Colors.red[900]),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('alertas')
                .orderBy('fecha', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hay alertas registradas."));
              }
              
              final allAlertas = snapshot.data!.docs;
              print("📦 Total alertas: ${allAlertas.length}");
              
              // Filtrar manualmente
              final filteredAlertas = allAlertas.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final alertDeviceId = data['deviceId']?.toString() ?? '';
                print("📋 Comparando: '$alertDeviceId' con '$deviceId'");
                return alertDeviceId == deviceId;
              }).toList();
              
              print("📦 Alertas filtradas: ${filteredAlertas.length}");
              
              if (filteredAlertas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("No hay alertas para el dispositivo: '$deviceId'"),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadDeviceId,
                        child: Text("Recargar"),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: filteredAlertas.length,
                itemBuilder: (context, index) {
                  final data = filteredAlertas[index].data() as Map<String, dynamic>;
                  final alertDeviceId = data['deviceId'];
                  final tipo = data['tipo'] ?? 'info';
                  final mensaje = data['mensaje'] ?? 'Mensaje desconocido';
                  final fecha = data['fecha'] as Timestamp?;
                  final fechaStr = fecha != null 
                      ? "${fecha.toDate().toLocal()}"
                      : "Fecha desconocida";
                  
                  print("📋 Mostrando alerta: deviceId=$alertDeviceId, tipo=$tipo");
                  
                  return _buildAlertItemCard({
                    'type': tipo,
                    'message': mensaje,
                    'date': fechaStr,
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('ALERTAS'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Histórico de Alertas',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'ID: $deviceId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: deviceId == null
                        ? const Center(child: Text("No hay deviceId"))
                        : _buildAlertList(deviceId!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _exportar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            child: const Text('Exportar', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _vaciar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            child: const Text('Vaciar', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      alert['message'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              if (alert.containsKey('date'))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 34.0),
                  child: Text(
                    alert['date'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}