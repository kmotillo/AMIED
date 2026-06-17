import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  static Future<void> generateAndDownloadProgressReport(List<dynamic> users) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    // Estadísticas
    int totalUsers = users.length;
    double avgXp = users.isEmpty ? 0 : users.map((u) => (u['total_xp'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / totalUsers;
    
    // Sort users by XP descending
    final sortedUsers = List<dynamic>.from(users);
    sortedUsers.sort((a, b) => ((b['total_xp'] as num?)?.toInt() ?? 0).compareTo((a['total_xp'] as num?)?.toInt() ?? 0));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Reporte de Progreso de Usuarios', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Fecha: $dateStr', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Resumen
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total de Usuarios', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('$totalUsers', style: const pw.TextStyle(fontSize: 18)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('XP Promedio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${avgXp.toStringAsFixed(1)} XP', style: const pw.TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            pw.Text('Lista Detallada', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            
            // Tabla
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Nombre', 'Email', 'Institución', 'Rol', 'Nivel', 'Total XP'],
              data: sortedUsers.map((u) {
                return [
                  u['full_name'] ?? 'N/A',
                  u['email'] ?? 'N/A',
                  u['institution'] ?? 'N/A',
                  u['role'] ?? 'N/A',
                  (u['current_level'] ?? 0).toString(),
                  (u['total_xp'] ?? 0).toString(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Progreso_Usuarios.pdf',
    );
  }
}
