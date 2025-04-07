import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class SuggestionsView extends StatefulWidget {
  const SuggestionsView({Key? key}) : super(key: key);

  @override
  _SuggestionsViewState createState() => _SuggestionsViewState();
}

class _SuggestionsViewState extends State<SuggestionsView> {
  String? deviceId;
  String? _debugError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _debugError = "Usuario no autenticado";
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();

      if (!doc.exists) {
        setState(() {
          _debugError = "Documento del usuario no encontrado en Firestore";
          _isLoading = false;
        });
        return;
      }

      final fetchedDeviceId = doc.data()?['deviceId'];
      if (fetchedDeviceId == null) {
        setState(() {
          _debugError = "⚠️ El campo 'deviceId' no existe en el documento de usuario.";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        deviceId = fetchedDeviceId.toString().trim();
        _debugError = null;
        _isLoading = false;
      });

      print("✅ deviceId cargado: $deviceId");
      
      // Test query to verify data retrieval
      _testQuery();
      
    } catch (e) {
      setState(() {
        _debugError = "Error al cargar datos: $e";
        _isLoading = false;
      });
      print("❌ Error en _loadDeviceId: $e");
    }
  }

  void _testQuery() async {
    if (deviceId == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
        .collection('sugerencias')
        .where('deviceId', isEqualTo: deviceId)
        .get();
      
      print("📋 Documentos encontrados: ${snapshot.docs.length}");
      for (var doc in snapshot.docs) {
        print("📄 Documento: ${doc.data()}");
      }
    } catch (e) {
      print("❌ Error en consulta: $e");
    }
  }

  void _vaciar() async {
    if (deviceId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sugerencias')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sugerencias eliminadas')),
      );
    } catch (e) {
      print("❌ Error al vaciar sugerencias: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar sugerencias: $e')),
      );
    }
  }

  void _showSuggestionDetails(Map<String, dynamic> suggestion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    suggestion['tipoAlerta'] == 'warning'
                        ? Icons.warning_amber_outlined
                        : suggestion['tipoAlerta'] == 'critical'
                            ? Icons.close
                            : Icons.info_outline,
                    color: suggestion['tipoAlerta'] == 'warning'
                        ? Colors.orange
                        : suggestion['tipoAlerta'] == 'critical'
                            ? Colors.red
                            : Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion['mensajeCorto'] ?? 'Sugerencia',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                suggestion['descripcion'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionItem(Map<String, dynamic> suggestion) {
    IconData icon;
    Color iconColor;

    switch (suggestion['tipoAlerta']) {
      case 'warning':
        icon = Icons.warning_amber_outlined;
        iconColor = Colors.orange;
        break;
      case 'critical':
        icon = Icons.close;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _showSuggestionDetails(suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    suggestion['mensajeCorto'] ?? 'Sugerencia',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionList() {
    print("🔍 Buscando sugerencias para deviceId: $deviceId");
    
    // Try getting data with a more permissive query first (for debugging)
    bool isDebugging = false; // Set to true to see all suggestions regardless of deviceId
    
    return StreamBuilder<QuerySnapshot>(
      stream: isDebugging 
        ? FirebaseFirestore.instance
            .collection('sugerencias')
            .orderBy('fecha', descending: true)
            .limit(10)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('sugerencias')
            .where('deviceId', isEqualTo: deviceId)
            .orderBy('fecha', descending: true)
            .snapshots(),
      builder: (context, snapshot) {
        print("📊 Estado del snapshot: ${snapshot.connectionState}");
        
        if (snapshot.hasError) {
          print("❌ Error: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("⚠️ No hay datos: ${snapshot.data?.docs.length ?? 0} documentos");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No hay sugerencias registradas."),
                if (isDebugging) 
                  Text("DeviceId: $deviceId", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        print("✅ Sugerencias cargadas: ${docs.length}");
        
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            // Debug print para cada item
            print("📱 Item $index: ${data['mensajeCorto']}");
            return _buildSuggestionItem(data);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('SUGERENCIAS'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : deviceId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _debugError ?? 'Error al cargar el dispositivo',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: _loadDeviceId,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
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
                            'Recomendaciones:',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'ID: ${deviceId?.substring(0, min(deviceId!.length, 6))}...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(child: _buildSuggestionList()),
                      const SizedBox(height: 20),
                      SizedBox(
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
                      const SizedBox(height: 20),
                      const FloatingBackButton(route: '/home'),
                    ],
                  ),
                ),
    );
  }
}