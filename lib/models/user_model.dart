class User {
  final int id;
  final String email;
  final String nombre;
  final String rol;

  User({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
  });

  // Convierte los datos que vienen de la Base de Datos (Map) a un objeto User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id_usuario'] ?? 0,
      email: map['email'] ?? '',
      nombre: map['nombre_completo'] ?? '',
      rol: map['rol'] ?? 'enfermera',
    );
  }
}