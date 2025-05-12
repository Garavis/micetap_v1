import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String? type;
  final String? message;
  final String? date;
  final DateTime? dateTime;
  String? docId; // Añadido para guardar el ID del documento

  Alert({this.type, this.message, this.date, this.dateTime, this.docId});

  factory Alert.fromFirestore(Map<String, dynamic> data) {
    DateTime? dateTime;
    String? dateStr;

    if (data['fecha'] is Timestamp) {
      dateTime = (data['fecha'] as Timestamp).toDate().toLocal();
      dateStr = dateTime.toString();
    }

    return Alert(
      type: data['tipo'],
      message: data['mensaje'],
      date: dateStr,
      dateTime: dateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {'type': type, 'message': message, 'date': date};
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
    final snapshot =
        await _firestore
            .collection('alertas')
            .where('deviceId', isEqualTo: deviceId)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final alert = Alert.fromFirestore(data);
      alert.docId = doc.id;
      return alert;
    }).toList();
  }

  Future<void> deleteAlertsByDeviceId(String deviceId) async {
    final snapshot =
        await _firestore
            .collection('alertas')
            .where('deviceId', isEqualTo: deviceId)
            .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
