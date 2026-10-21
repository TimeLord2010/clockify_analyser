import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/reports/report_data.dart';
import 'package:clockify/features/reports/report_exporter.dart';
import 'package:clockify/features/reports/report_pdf.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:clockify/services/logger.dart';
import 'package:clockify/ui/components/atoms/selected_date_range_picker.dart';
import 'package:clockify/ui/components/atoms/selected_user_picker.dart';
import 'package:clockify/ui/components/molecules/cumulative_hours_chart.dart';
import 'package:clockify/ui/components/molecules/grouped_entries_chart.dart';
import 'package:clockify/ui/components/molecules/total_by_day.dart';
import 'package:clockify/ui/components/molecules/total_gain_by_project.dart';
import 'package:clockify/ui/components/molecules/trending_times.dart';
import 'package:clockify/ui/providers/date_range_provider.dart';
import 'package:clockify/ui/providers/projects_provider.dart';
import 'package:clockify/ui/providers/selected_user_provider.dart';
import 'package:clockify/ui/providers/selected_workspace_provider.dart';
import 'package:clockify/ui/providers/time_entries_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class WorkspaceSummary extends ConsumerStatefulWidget {
  const WorkspaceSummary({super.key});

  @override
  ConsumerState<WorkspaceSummary> createState() => _WorkspaceSummaryState();
}

class _WorkspaceSummaryState extends ConsumerState<WorkspaceSummary> {
  bool _showHeatmap = false;
  bool _isGeneratingReport = false;

  final logger = createLogger('WorkspaceSummary');

  @override
  Widget build(BuildContext context) {
    var projects = ref.watch(projectsProvider);
    var entriesAsync = ref.watch(mergedTimeEntriesForWorkspaceProvider);
    var selectedUser = ref.watch(selectedUserProvider);
    var projectMap = <String, Project>{
      for (var item in projects) item.id: item,
    };
    var rates = LocalStorageModule.customHourlyRates;

    return entriesAsync.when(
      data: (entries) {
        var gainManager = TimeEntriesGainManager(
          timeEntries: entries,
          projects: projects,
          customHourlyRates: rates,
          currentUserId: selectedUser?.id,
        );

        return _buildContent(context, entries, gainManager, projectMap);
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Erro ao carregar entradas de tempo')),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<TimeEntry> entries,
    TimeEntriesGainManager gainManager,
    Map<String, Project> projectMap,
  ) {
    return Column(
      children: [
        _filters(context),
        Gap(5),
        _topBar(gainManager),
        Gap(5),
        TotalByDay(gainManager: gainManager, height: 110),
        Gap(2),
        Expanded(child: CumulativeHoursChart(gainManager: gainManager)),
        _toggleChartButton(),
        Gap(5),
        SizedBox(
          height: 200,
          child: _showHeatmap
              ? TrendingTimes(gainManager: gainManager)
              : GroupedEntriesChart(),
        ),
      ],
    );
  }

  Container _topBar(TimeEntriesGainManager gainManager) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5),
      height: 68,
      child: Row(
        spacing: 10,
        children: [
          Expanded(child: TotalGainByProject(gainManager: gainManager)),
          _reportButton(),
        ],
      ),
    );
  }

  /// Generates the PDF report for the period shown on this screen.
  Widget _reportButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the label only when the bar has room for it.
        final compact = MediaQuery.sizeOf(context).width < 520;
        final icon = _isGeneratingReport
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf_outlined, size: 18);

        if (compact) {
          return IconButton.filledTonal(
            onPressed: _isGeneratingReport ? null : _generateReport,
            tooltip: 'Gerar relatório em PDF',
            icon: icon,
          );
        }

        return FilledButton.tonalIcon(
          onPressed: _isGeneratingReport ? null : _generateReport,
          icon: icon,
          label: Text(
            _isGeneratingReport ? 'Gerando…' : 'Relatório PDF',
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }

  Future<void> _generateReport() async {
    if (_isGeneratingReport) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isGeneratingReport = true);

    try {
      final entries =
          ref.read(mergedTimeEntriesForWorkspaceProvider).valueOrNull ??
          const <TimeEntry>[];
      final projects = ref.read(projectsProvider);
      final user = ref.read(selectedUserProvider);
      final workspace = ref.read(selectedWorkspaceProvider).valueOrNull;
      final range = ref.read(dateRangeProvider);

      final data = buildReportData(
        entries: entries,
        projects: projects,
        customHourlyRates: LocalStorageModule.customHourlyRates,
        workspaceName: workspace?.name ?? 'Workspace',
        userName: user?.name ?? 'Todos os usuários',
        startDate: range.startDate,
        endDate: range.endDate,
        currentUserId: user?.id,
      );

      if (data.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Nenhuma hora registrada no período selecionado.'),
          ),
        );
        return;
      }

      final bytes = await buildReportPdf(data);
      final fileName =
          'relatorio-${_fileDate(data.startDate)}_${_fileDate(data.endDate)}.pdf';
      final destination = await saveReportFile(bytes, fileName);

      logger.i(
        'Relatório gerado: $fileName '
        '(${data.projects.length} projetos, ${data.entryCount} registros)',
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Relatório gerado: $destination')),
      );
    } catch (error, stackTrace) {
      logger.e(
        'Falha ao gerar relatório',
        error: error,
        stackTrace: stackTrace,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao gerar relatório: $error')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  String _fileDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Align _toggleChartButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextButton.icon(
          onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
          icon: Icon(_showHeatmap ? Icons.bar_chart : Icons.grid_on, size: 16),
          label: Text(
            _showHeatmap ? 'Show entries' : 'Show activity heatmap',
            style: TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ),
    );
  }

  Widget _filters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var width = constraints.maxWidth;
          if (width < 500) {
            return SizedBox.shrink();
          }

          // Wide layout
          return Row(
            children: [
              Gap(8),
              SelectedDateRangePicker(),
              Spacer(),
              SelectedUserPicker(),
            ],
          );
        },
      ),
    );
  }
}
