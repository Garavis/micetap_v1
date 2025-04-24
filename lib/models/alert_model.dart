import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String? type;
  final String? message;
  final String? date;
  
  Alert({
    this.type,
    this.message,
    this.date,
  });
  
  factory Alert.fromFirestore(Map<String, dynamic> data) {
    return Alert(
      type: data['tipo'],
      message: data['mensaje'],
      date: (data['fecha'] as Timestamp?)?.toDate().toLocal().toString(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'date': date,
    };
  }
}

class AlertsModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<QuerySnapshot> getAlertsStream() {
    return _firestore
        .collection('alertas')
        .orderBy('fecha', descending: true)
        .snapshots();
  }
  
  Future<List<Alert>> getAlertsByDeviceId(String deviceId) async {
    final snapshot = await _firestore
        .collection('alertas')
        .where('deviceId', isEqualTo: deviceId)
        .get();
        
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Alert.fromFirestore(data);
    }).toList();
  }
  
  Future<void> deleteAlertsByDeviceId(String deviceId) async {
    final snapshot = await _firestore
        .collection('alertas')
        .where('deviceId', isEqualTo: deviceId)
        .get();
        
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}