// Regression guard for the report top bar: the PDF button must sit on the same
// line as the daily average (not centered on the whole 68px bar, which also
// holds the project labels row) and keep a small gap from it.
//
// Uses the real widgets with synthetic entries — no network, no mocks.
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:clockify/ui/components/molecules/total_gain_by_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

const _userId = 'u1';

TimeEntriesGainManager _manager() {
  final projects = [
    Project(
      id: 'p1',
      name: 'LEIA',
      color: '1F6FEB',
      archived: false,
      memberships: [
        Membership(userId: _userId, hourlyRate: HourlyRate(amount: 120)),
      ],
    ),
    Project(
      id: 'p2',
      name: 'GRAV',
      color: '10B981',
      archived: false,
      memberships: [
        Membership(userId: _userId, hourlyRate: HourlyRate(amount: 95)),
      ],
    ),
  ];

  final entries = <TimeEntry>[];
  var day = DateTime(2026, 10, 1, 9);
  for (var i = 0; i < 10; i++) {
    entries.add(
      TimeEntry(
        id: 'e$i',
        description: 'Tarefa $i',
        hourlyRate: HourlyRate(amount: 120),
        projectId: i.isEven ? 'p1' : 'p2',
        userId: _userId,
        timeInterval: TimeInterval(
          start: day,
          end: day.add(const Duration(minutes: 90)),
        ),
      ),
    );
    day = day.add(const Duration(days: 1));
  }

  return TimeEntriesGainManager(
    timeEntries: entries,
    projects: projects,
    customHourlyRates: const {},
    currentUserId: _userId,
  );
}

Widget _labelButton() {
  return FilledButton.tonalIcon(
    onPressed: () {},
    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
    label: const Text('Relatório PDF', style: TextStyle(fontSize: 12)),
    style: FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}

Widget _bar({double width = 1100}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: Container(
            key: const ValueKey('bar'),
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: TotalGainByProject(
              gainManager: _manager(),
              trailing: _labelButton(),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('report button shares the daily average line', (tester) async {
    tester.view.physicalSize = const Size(1200, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_bar());
    await tester.pumpAndSettle(const Duration(milliseconds: 900));

    final gauge = tester.getRect(find.byType(ClipRRect).first);
    final button = tester.getRect(find.byType(FilledButton).first);
    final meanLabel = tester.getRect(find.text('Média diária'));

    expect(
      (button.center.dy - gauge.center.dy).abs(),
      lessThan(0.5),
      reason: 'botão deve estar na mesma linha do gráfico/média diária',
    );
    expect(
      button.left - meanLabel.right,
      inInclusiveRange(12, 20),
      reason: 'espaçamento pequeno entre média diária e botão',
    );
  });
}
