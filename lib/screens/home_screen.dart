// lib/screens/admin_management_screen.dart (VERSION CON BAJAS)

import 'package:flutter/material.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with SingleTickerProviderStateMixin {
  
  // Ahora necesitamos 3 pestañas: Doctor, Enfermera, Gestión/Bajas
  late TabController _tabController;
  final GlobalKey<FormState> _doctorFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _nurseFormKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // <-- Longitud 3
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Método de Simulación de Guardado/Actualización ---
  void _saveUser(String role, GlobalKey<FormState> formKey) {
    if (formKey.currentState!.validate()) {
      // Lógica de INSERT...
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Datos de $role guardados con éxito (Simulación de INSERT en BD).'),
          backgroundColor: Colors.green,
        ),
      );
      formKey.currentState!.reset();
    }
  }

  // --- Método de Simulación de Baja/Desactivación ---
  void _deactivateUser() {
    final identifier = _searchController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Por favor, ingrese el Email o Cédula para dar de baja.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // En la base de datos (BD), esto se maneja con un UPDATE:
    // UPDATE Usuarios SET estado = 'inactivo', fecha_baja = NOW() WHERE email = 'identificador' OR cedula_profesional = 'identificador'
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛑 Usuario con identificador "$identifier" marcado como INACTIVO (Simulación de UPDATE en BD).'),
        backgroundColor: Colors.red,
      ),
    );
    _searchController.clear();
  }


  // --- Widget del Formulario de CREACIÓN (Reutilizable) ---
  Widget _buildUserForm({required String role, required GlobalKey<FormState> formKey}) {
    final Color primaryColor = role == 'Doctor' ? Colors.red[800]! : Colors.teal[800]!;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Registro de $role',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const Divider(color: Colors.grey),

            // Campos que mapean a la BD (nombre_completo, email, password_hash, cedula_profesional, firma_digital)
            _buildTextField(label: 'Nombre Completo', icon: Icons.person_outline, isRequired: true, hint: 'Ej: Juan Pérez García'),
            _buildTextField(label: 'Correo Electrónico (Login ID)', icon: Icons.email, keyboardType: TextInputType.emailAddress, isRequired: true, hint: 'correo@ejemplo.com'),
            _buildTextField(label: 'Contraseña Provisional (Asignada por Admin)', icon: Icons.lock, isPassword: true, isRequired: true),
            _buildTextField(label: 'Cédula Profesional / Matrícula', icon: Icons.badge, isRequired: true),
            _buildTextField(label: 'Firma Digital (URL/ID)', icon: Icons.fingerprint, isRequired: false, hint: 'Campo para el ID o URL de la firma'),
            
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () => _saveUser(role, formKey),
              icon: const Icon(Icons.save),
              label: Text('Guardar Datos del $role'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget de Gestión de BAJAS ---
  Widget _buildDeactivationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Gestión de Bajas y Desactivación',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const Divider(color: Colors.grey),

          const Text(
            'Para dar de baja a un usuario (Doctor o Enfermera), ingrese su Correo Electrónico o su Cédula Profesional.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // Campo de búsqueda/identificación
          _buildTextField(
            controller: _searchController,
            label: 'Email o Cédula a Desactivar',
            icon: Icons.person_off,
            isRequired: true,
            hint: 'ID único del usuario',
          ),

          const SizedBox(height: 20),
          
          ElevatedButton.icon(
            onPressed: _deactivateUser,
            icon: const Icon(Icons.warning_amber),
            label: const Text('Dar de Baja / Desactivar Usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700], // Color de advertencia
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          
          const SizedBox(height: 20),
          const Text(
            'Nota Importante: En bases de datos de salud, los usuarios no se eliminan permanentemente (DELETE), sino que se marcan como inactivos (UPDATE estado = 0) por razones de trazabilidad y auditoría.',
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isRequired = false,
    String? Function(String?)? validator,
    String hint = '',
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller, // <-- Añadido el controlador
        keyboardType: keyboardType,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        validator: validator ?? (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Este campo es obligatorio.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Panel de Administración de Usuarios'),
        backgroundColor: Colors.blueGrey,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Doctor', icon: Icon(Icons.local_hospital)),
            Tab(text: 'Enfermera', icon: Icon(Icons.medical_services)),
            Tab(text: 'Bajas/Gestión', icon: Icon(Icons.remove_circle)), // Nueva Pestaña
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: Doctor
          _buildUserForm(role: 'Doctor', formKey: _doctorFormKey),
          // Pestaña 2: Enfermera
          _buildUserForm(role: 'Enfermera', formKey: _nurseFormKey),
          // Pestaña 3: Gestión de Bajas
          _buildDeactivationForm(), 
        ],
      ),
    );
  }
}