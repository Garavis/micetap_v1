class UserConfigModel {
  final String uid;
  final String nombre;
  final String deviceId;
  final String email;
  final String createdAt;
  final String lastLogin;
  final String profileType;
  final int estrato; // Nuevo campo para estrato
  final Map<String, dynamic>? additionalInfo;

  UserConfigModel({
    required this.uid,
    required this.nombre,
    required this.deviceId,
    required this.email,
    this.createdAt = '',
    this.lastLogin = '',
    this.profileType = 'Estándar',
    this.estrato = 1, // Valor predeterminado: estrato 1
    this.additionalInfo,
  });

  factory UserConfigModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserConfigModel(
      uid: uid,
      nombre: data['nombre'] ?? 'Sin nombre',
      deviceId: data['deviceId'] ?? 'Sin ID',
      email: data['email'] ?? 'Sin correo',
      createdAt: data['createdAt'] ?? '',
      lastLogin: data['lastLogin'] ?? '',
      estrato: data['estrato'] ?? 1, // Extraer estrato o asignar 1 por defecto
      additionalInfo: data['additionalInfo'],
    );
  }

  factory UserConfigModel.empty() {
    return UserConfigModel(
      uid: '',
      nombre: 'Sin nombre',
      deviceId: 'Sin ID',
      email: 'Sin correo',
    );
  }
}
