import 'package:flutter/material.dart';
class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Panel Doctor")), body: const Center(child: Text("Bienvenido Doctor")));
  }
}