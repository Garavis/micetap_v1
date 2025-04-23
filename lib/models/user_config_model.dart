class UserConfigModel {
  final String uid;
  final String nombre;
  final String deviceId;
  
  UserConfigModel({
    required this.uid,
    required this.nombre,
    required this.deviceId,
  });
  
  factory UserConfigModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserConfigModel(
      uid: uid,
      nombre: data['nombre'] ?? 'Sin nombre',
      deviceId: data['deviceId'] ?? 'Sin ID',
    );
  }
  
  factory UserConfigModel.empty() {
    return UserConfigModel(
      uid: '',
      nombre: 'Sin nombre',
      deviceId: 'Sin ID',
    );
  }
}