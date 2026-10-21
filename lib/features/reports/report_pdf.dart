import 'dart:typed_data';

import 'package:clockify/features/reports/report_data.dart';
import 'package:clockify/features/usecases/duration/format_duration.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds the PDF report for a period, with no Flutter dependency so it can be
/// rendered from a plain `dart run` script (see `scripts/report_sample.dart`).
Future<Uint8List> buildReportPdf(ReportData data) async {
  final doc = pw.Document(
    title: 'Relatório de horas - ${data.workspaceName}',
    author: 'Clockify Analyser',
    creator: 'Clockify Analyser',
  );

  final theme = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
  );

  const accent = PdfColor.fromInt(0xFF1F6FEB);
  final grey = PdfColor.fromInt(0xFF6B7280);
  final headerBand = PdfColor.fromInt(0xFFEAF2FF);
  final border = PdfColor.fromInt(0xFFE5E7EB);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 36),
      theme: theme,
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'Clockify Analyser · página ${context.pageNumber} de '
          '${context.pagesCount}',
          style: pw.TextStyle(fontSize: 7.5, color: grey),
        ),
      ),
      build: (context) => [
        _header(data, accent, grey),
        pw.SizedBox(height: 10),
        _paymentHeader(data, accent, grey, headerBand),
        pw.SizedBox(height: 18),
        _sectionTitle('Horas por projeto', accent),
        pw.SizedBox(height: 8),
        _projectSection(data, grey, border, accent),
        pw.SizedBox(height: 18),
        _sectionTitle('Top $reportTopTasksCount tarefas', accent),
        pw.SizedBox(height: 8),
        _topTasks(data, grey, border, headerBand),
        if (data.otherTasks.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          _sectionTitle('Outras tarefas', accent),
          pw.SizedBox(height: 6),
          _otherTasks(data, grey),
        ],
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header(ReportData data, PdfColor accent, PdfColor grey) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              'Relatório de horas',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
          ),
          pw.Text(
            'Gerado em ${_dateTime(data.generatedAt)}',
            style: pw.TextStyle(fontSize: 8, color: grey),
          ),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        '${data.workspaceName} · ${data.userName}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'Período: ${_date(data.startDate)} a ${_date(data.endDate)} · '
        '${data.businessDays} dias úteis · ${data.entryCount} registros',
        style: pw.TextStyle(fontSize: 9, color: grey),
      ),
    ],
  );
}

/// The headline of the report: how much is owed for the period, plus the
/// secondary numbers that back it up.
pw.Widget _paymentHeader(
  ReportData data,
  PdfColor accent,
  PdfColor grey,
  PdfColor background,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: pw.BoxDecoration(
      color: background,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TOTAL A RECEBER',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: grey,
                  letterSpacing: 0.6,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _money(data.totalGain),
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
        _headerMetric('Horas totais', formatDuration(data.totalDuration), grey),
        pw.SizedBox(width: 16),
        _headerMetric('Média diária', formatDuration(data.meanByDay), grey),
        pw.SizedBox(width: 16),
        _headerMetric('Projetos', '${data.projects.length}', grey),
      ],
    ),
  );
}

pw.Widget _headerMetric(String label, String value, PdfColor grey) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 7.5, color: grey)),
      pw.SizedBox(height: 2),
      pw.Text(
        value,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}

pw.Widget _sectionTitle(String title, PdfColor accent) {
  return pw.Row(
    children: [
      pw.Container(width: 3, height: 12, color: accent),
      pw.SizedBox(width: 6),
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}

/// Pie chart next to the per-project table (hours, share and payout).
pw.Widget _projectSection(
  ReportData data,
  PdfColor grey,
  PdfColor border,
  PdfColor accent,
) {
  final pie = pw.SizedBox(
    width: 140,
    height: 140,
    child: pw.Chart(
      grid: pw.PieGrid(),
      datasets: [
        for (var i = 0; i < data.projects.length; i++)
          pw.PieDataSet(
            value: data.projects[i].duration.inMinutes.toDouble(),
            color: _sliceColor(data.projects[i].colorHex, i),
            legendPosition: pw.PieLegendPosition.none,
            borderColor: PdfColors.white,
            borderWidth: 1,
          ),
      ],
    ),
  );

  final table = _projectTable(data, grey, border, accent);

  if (data.projects.length <= 8) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pie,
        pw.SizedBox(width: 16),
        pw.Expanded(child: table),
      ],
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Center(child: pie),
      pw.SizedBox(height: 10),
      table,
    ],
  );
}

pw.Widget _projectTable(
  ReportData data,
  PdfColor grey,
  PdfColor border,
  PdfColor accent,
) {
  pw.Widget cell(
    String text, {
    required int flex,
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
    pw.Widget? leading,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Row(
          mainAxisAlignment: align == pw.TextAlign.right
              ? pw.MainAxisAlignment.end
              : pw.MainAxisAlignment.start,
          children: [
            if (leading != null) ...[leading, pw.SizedBox(width: 5)],
            pw.Flexible(
              child: pw.Text(
                text,
                textAlign: align,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: color ?? (bold ? PdfColors.black : grey),
                  fontWeight: bold ? pw.FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget fixedCell(
    String text, {
    required double width,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.SizedBox(
      width: width,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: 9,
            color: color ?? (bold ? PdfColors.black : grey),
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  return pw.Column(
    children: [
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.8)),
        ),
        child: pw.Row(
          children: [
            cell('Projeto', flex: 4, bold: true),
            fixedCell('Horas', width: 50, bold: true),
            fixedCell('%', width: 36, bold: true),
            fixedCell('Valor', width: 62, bold: true),
          ],
        ),
      ),
      for (var i = 0; i < data.projects.length; i++)
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.4)),
          ),
          child: pw.Row(
            children: [
              cell(
                data.projects[i].name,
                flex: 4,
                leading: pw.Container(
                  width: 7,
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: _sliceColor(data.projects[i].colorHex, i),
                    borderRadius: pw.BorderRadius.circular(3.5),
                  ),
                ),
              ),
              fixedCell(formatDuration(data.projects[i].duration), width: 50),
              fixedCell(_percent(data.projects[i].share), width: 36),
              fixedCell(_money(data.projects[i].gain), width: 62, bold: true),
            ],
          ),
        ),
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Row(
          children: [
            cell('Total', flex: 4, bold: true, color: accent),
            fixedCell(
              formatDuration(data.totalDuration),
              width: 50,
              bold: true,
            ),
            fixedCell('100%', width: 36, bold: true),
            fixedCell(_money(data.totalGain), width: 62, bold: true),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _topTasks(
  ReportData data,
  PdfColor grey,
  PdfColor border,
  PdfColor headerBackground,
) {
  pw.Widget cell(
    String text, {
    required int flex,
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 9,
            color: bold ? PdfColors.black : grey,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  return pw.Column(
    children: [
      pw.Container(
        color: headerBackground,
        child: pw.Row(
          children: [
            cell('#', flex: 1, bold: true),
            cell('Tarefa', flex: 5, bold: true),
            cell('Projeto', flex: 3, bold: true),
            cell('Horas', flex: 2, bold: true, align: pw.TextAlign.right),
            cell('%', flex: 1, bold: true, align: pw.TextAlign.right),
          ],
        ),
      ),
      for (var i = 0; i < data.topTasks.length; i++)
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.5)),
          ),
          child: pw.Row(
            children: [
              cell('${i + 1}', flex: 1),
              cell(data.topTasks[i].description, flex: 5),
              cell(data.topTasks[i].projectName, flex: 3),
              cell(
                formatDuration(data.topTasks[i].duration),
                flex: 2,
                align: pw.TextAlign.right,
              ),
              cell(
                _percent(data.topTasks[i].share),
                flex: 1,
                align: pw.TextAlign.right,
                bold: true,
              ),
            ],
          ),
        ),
    ],
  );
}

/// The remaining tasks: same information, deliberately quieter.
pw.Widget _otherTasks(ReportData data, PdfColor grey) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '${data.otherTasks.length} tarefas · '
        '${formatDuration(data.otherTasksDuration)} no total',
        style: pw.TextStyle(fontSize: 7.5, color: grey),
      ),
      pw.SizedBox(height: 3),
      for (final task in data.otherTasks)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 1.5),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 6,
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 3,
                      height: 3,
                      decoration: pw.BoxDecoration(
                        color: grey,
                        borderRadius: pw.BorderRadius.circular(1.5),
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                      child: pw.Text(
                        task.description,
                        style: pw.TextStyle(fontSize: 7.5, color: grey),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  task.projectName,
                  style: pw.TextStyle(fontSize: 7.5, color: grey),
                ),
              ),
              pw.SizedBox(
                width: 45,
                child: pw.Text(
                  formatDuration(task.duration),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 7.5, color: grey),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Clockify project color, parsed the same way the app does (AARRGGBB when
/// 8 digits, implicit opaque alpha when 6), with a deterministic fallback
/// palette for missing/malformed values.
PdfColor _sliceColor(String colorHex, int index) {
  const fallback = [
    0xFF3B82F6,
    0xFF10B981,
    0xFFF59E0B,
    0xFF8B5CF6,
    0xFFEF4444,
    0xFF06B6D4,
    0xFFEC4899,
    0xFF84CC16,
    0xFF6366F1,
    0xFFF97316,
  ];

  final argb = _parseArgb(colorHex);
  if (argb == null) {
    return PdfColor.fromInt(fallback[index % fallback.length]);
  }

  return PdfColor(
    ((argb >> 16) & 0xFF) / 255.0,
    ((argb >> 8) & 0xFF) / 255.0,
    (argb & 0xFF) / 255.0,
  );
}

/// Parses `RGB`, `RRGGBB` or `AARRGGBB` (with or without `#`) into an ARGB int.
int? _parseArgb(String value) {
  var hex = value.trim().replaceFirst('#', '');
  if (hex.isEmpty) return null;

  if (hex.length == 3) {
    hex = hex.split('').map((char) => '$char$char').join();
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;

  return int.tryParse(hex, radix: 16);
}

String _percent(double share) => '${(share * 100).toStringAsFixed(1)}%';

String _money(double value) => '\$ ${value.toStringAsFixed(2)}';

String _two(int value) => value.toString().padLeft(2, '0');

String _date(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}/${date.year}';

String _dateTime(DateTime date) =>
    '${_date(date)} ${_two(date.hour)}:${_two(date.minute)}';
