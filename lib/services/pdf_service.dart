// lib/services/pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> imprimirReceta({
    required Map<String, dynamic> pacienteData,
    required List<Map<String, dynamic>> medicamentos,
    required String diagnostico,
    String doctorNombre = "Dr. Roberto Salas",
    String cedulaDoctor = "12345678",
  }) async {
    final doc = pw.Document();
    final fechaHoy = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text("RECETA MÉDICA - HOSPITAL GENERAL TESI", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text("Fecha: $fechaHoy"),
              pw.Text("Doctor: $doctorNombre (Cédula: $cedulaDoctor)"),
              pw.SizedBox(height: 20),
              pw.Text("Paciente: ${pacienteData['nombre']}"),
              pw.Text("Diagnóstico: $diagnostico"),
              pw.SizedBox(height: 20),
              pw.Text("TRATAMIENTO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...medicamentos.map((m) => pw.Bullet(text: "${m['nombre']} - ${m['dosis']} - ${m['frecuencia']} por ${m['duracion']} días")),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receta.pdf',
    );
  }
}