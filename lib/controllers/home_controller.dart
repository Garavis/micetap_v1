import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:micetap_v1/models/home_model.dart';

class HomeController {
  final HomeModel _model = HomeModel(); 
  
  Stream<DocumentSnapshot> getConsumoStream(String deviceId) {
    return _model.getConsumoStream(deviceId);
  }
  
  double getConsumoFromSnapshot(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      return 0.0;
    }
    
    final data = snapshot.data() as Map<String, dynamic>?;
    return data?['consumo'] ?? 0.0;
  }
}