import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  
  /// Genera el PDF y lanza la interfaz de impresión nativa
  static Future<void> imprimirReceta({
    required Map<String, dynamic> pacienteData,
    required List<Map<String, dynamic>> medicamentos, // Ajustado a dynamic para coincidir con tu lista
    required String diagnostico,
    String doctorNombre = "Dr. Roberto Salas", // Puedes hacerlo dinámico si tienes el usuario logueado
    String cedulaDoctor = "12345678",
  }) async {
    
    final doc = pw.Document();
    final fechaHoy = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Definimos una fuente base si es necesario, pero la por defecto funciona bien para español
    
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- ENCABEZADO ---
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("HOSPITAL GENERAL TESI", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    // Aquí podrías poner un logo con pw.Image
                    pw.PdfLogo(), 
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // --- DATOS DEL DOCTOR ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Médico: $doctorNombre", style: const pw.TextStyle(fontSize: 12)),
                  pw.Text("Fecha: $fechaHoy", style: const pw.TextStyle(fontSize: 12)),
                ]
              ),
              pw.Divider(),

              // --- FICHA DEL PACIENTE ---
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("PACIENTE: ${pacienteData['nombre']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Edad: ${pacienteData['edad']} años"),
                        pw.Text("CURP: ${pacienteData['curp']}"),
                        pw.Text("Sexo: ${pacienteData['genero']}"),
                      ]
                    ),
                  ]
                )
              ),
              pw.SizedBox(height: 15),
              
              // --- DIAGNÓSTICO ---
              pw.Text("Diagnóstico Médico:", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(diagnostico, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 20),

              // --- TABLA DE MEDICAMENTOS ---
              pw.Text("PLAN DE TRATAMIENTO (RECETA)", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              if (medicamentos.isEmpty)
                pw.Text("No se han prescrito medicamentos.", style: const pw.TextStyle(color: PdfColors.grey))
              else
                pw.Table.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.center,
                  },
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3), // Nombre más ancho
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1),
                  },
                  headers: ['Medicamento', 'Dosis', 'Frecuencia', 'Días'],
                  data: medicamentos.map((m) => [
                    m['nombre'] ?? '',
                    m['dosis'] ?? '',
                    m['frecuencia'] ?? '',
                    m['duracion'] ?? ''
                  ]).toList(),
                ),

              pw.Spacer(),

              // --- FIRMA ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 180, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text(doctorNombre, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Cédula Profesional: $cedulaDoctor"),
                    ]
                  )
                ]
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Documento generado digitalmente por Sistema de Triage Médico", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
            ],
          );
        },
      ),
    );

    // Lanza la impresión
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receta_${pacienteData['curp']}.pdf',
    );
  }
}