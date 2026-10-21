// Renders a report PDF from synthetic data so the layout can be inspected
// without hitting the Clockify API.
//
//   dart run scripts/report_sample.dart [out.pdf] [--many-projects]
//
// This is a development/QA harness, not production code.
import 'dart:io';

import 'package:clockify/features/reports/report_data.dart';
import 'package:clockify/features/reports/report_pdf.dart';
import 'package:clockify/features/usecases/duration/format_duration.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

const _userId = 'user-1';

class _ProjectSpec {
  final String id;
  final String name;
  final String color;
  final double rate;
  final List<_TaskSpec> tasks;

  _ProjectSpec(this.id, this.name, this.color, this.rate, this.tasks);
}

class _TaskSpec {
  final String description;
  final int sessions;
  final int minutes;

  _TaskSpec(this.description, this.sessions, this.minutes);
}

void main(List<String> args) {
  final outputPath = args.firstWhere(
    (arg) => !arg.startsWith('--'),
    orElse: () => 'build/report_sample.pdf',
  );
  final manyProjects = args.contains('--many-projects');

  // Colors exactly as the SDK delivers them: no leading '#', sometimes
  // 8-digit ARGB (as `colorToHex` produces), sometimes 6-digit from Clockify.
  final specs = <_ProjectSpec>[
    _ProjectSpec('p1', 'LEIA - Plataforma', '1F6FEB', 120, [
      _TaskSpec('Refatorar módulo de autenticação', 6, 175),
      _TaskSpec('Revisão de PRs do time', 9, 120),
      _TaskSpec('Migração do banco para Postgres 16', 3, 210),
      _TaskSpec('Ajustes de layout no painel admin', 2, 45),
      _TaskSpec('Correção de bug no upload de anexos', 1, 25),
    ]),
    _ProjectSpec('p2', 'GRAV - Atendimento', 'FF10B981', 95, [
      _TaskSpec('Reunião de alinhamento semanal', 4, 240),
      _TaskSpec('Documentação do fluxo de atendimento', 3, 150),
      _TaskSpec('Treinamento da equipe de suporte', 2, 180),
      _TaskSpec('Ajuste no template do WhatsApp', 1, 30),
    ]),
    _ProjectSpec('p3', 'Interno - Estudos', 'F59E0B', 0, [
      _TaskSpec('Curso de arquitetura de software', 5, 300),
      _TaskSpec('Leitura de documentação do Riverpod', 2, 90),
    ]),
    _ProjectSpec('p4', 'Cliente VIT - App', 'FF8B5CF6', 150, [
      _TaskSpec('Implementar tela de cronômetro', 4, 260),
      _TaskSpec('Integração com a API do Clockify', 2, 140),
      _TaskSpec('Ajustes de acessibilidade', 1, 35),
    ]),
    _ProjectSpec('p5', 'Suporte', 'EF4444', 80, [
      _TaskSpec('Tickets de suporte nível 2', 7, 195),
      _TaskSpec('Plantão de incidentes', 2, 60),
    ]),
  ];

  if (manyProjects) {
    for (var i = 6; i <= 13; i++) {
      specs.add(
        _ProjectSpec(
          'p$i',
          'Projeto extra $i',
          ['06B6D4', 'FFEC4899', '84CC16', 'FF6366F1'][i % 4],
          100,
          [_TaskSpec('Demanda $i', 1, 30 + i * 5)],
        ),
      );
    }
  }

  final projects = <Project>[
    for (final spec in specs)
      Project(
        id: spec.id,
        name: spec.name,
        color: spec.color,
        archived: false,
        memberships: [
          Membership(
            userId: _userId,
            hourlyRate: HourlyRate(amount: spec.rate),
          ),
        ],
      ),
  ];

  final entries = <TimeEntry>[];
  var dayCursor = DateTime(2026, 10, 1);
  var entryId = 0;

  for (final spec in specs) {
    for (final task in spec.tasks) {
      for (var session = 0; session < task.sessions; session++) {
        final start = DateTime(
          dayCursor.year,
          dayCursor.month,
          dayCursor.day,
          9,
          0,
        );
        entries.add(
          TimeEntry(
            id: 'e${entryId++}',
            description: task.description,
            hourlyRate: HourlyRate(amount: spec.rate),
            projectId: spec.id,
            userId: _userId,
            timeInterval: TimeInterval(
              start: start,
              end: start.add(Duration(minutes: task.minutes)),
            ),
          ),
        );
        dayCursor = dayCursor.add(const Duration(days: 1));
        if (dayCursor.month != 10) dayCursor = DateTime(2026, 10, 1);
      }
    }
  }

  final data = buildReportData(
    entries: entries,
    projects: projects,
    customHourlyRates: const {},
    workspaceName: 'VIT Studio',
    userName: 'Vinicius Example',
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 10, 31),
    currentUserId: _userId,
    generatedAt: DateTime(2026, 10, 21, 14, 32),
  );

  stdout.writeln('entries: ${data.entryCount}');
  stdout.writeln('total:   ${formatDuration(data.totalDuration)}');
  stdout.writeln('mean:    ${formatDuration(data.meanByDay)} / dia útil');
  stdout.writeln('gain:    \$${data.totalGain.toStringAsFixed(2)}');
  for (final slice in data.projects) {
    stdout.writeln(
      '  ${slice.name.padRight(24)} '
      '${formatDuration(slice.duration).padLeft(8)} '
      '${(slice.share * 100).toStringAsFixed(1).padLeft(6)}% '
      '\$${slice.gain.toStringAsFixed(2)}',
    );
  }
  stdout.writeln('top tasks: ${data.topTasks.length}');
  stdout.writeln('other tasks: ${data.otherTasks.length}');

  buildReportPdf(data).then((bytes) {
    final file = File(outputPath)..parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    stdout.writeln('PDF: ${file.absolute.path} (${bytes.length} bytes)');
  });
}
