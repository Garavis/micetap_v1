import 'package:cloud_firestore/cloud_firestore.dart';

class HomeModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<DocumentSnapshot> getConsumoStream(String deviceId) {
    return _firestore
        .collection('dispositivos')
        .doc(deviceId)
        .snapshots();
  }
}