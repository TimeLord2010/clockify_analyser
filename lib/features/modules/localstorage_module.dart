import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vit_clockify_sdk/vit_clockify_sdk.dart';

class LocalStorageModule {
  static SharedPreferences get _sp => GetIt.I.get<SharedPreferences>();

  static String get clockifyKey {
    return _sp.getString('clockify_key') ?? '';
  }

  static set clockifyKey(String value) {
    _sp.setString('clockify_key', value);
  }

  static Map<String, double> get customHourlyRates {
    var json = _sp.getString('customHourlyRates') ?? '{}';
    Map<String, dynamic> map = jsonDecode(json);
    return {
      for (var item in map.entries) item.key: (item.value as num).toDouble(),
    };
  }

  static set customHourlyRates(Map<String, double> hourlyRates) {
    var json = jsonEncode(hourlyRates);
    _sp.setString('customHourlyRates', json);
  }

  static double? getHourlyRate(String projectId) {
    var rates = customHourlyRates;
    return rates[projectId];
  }

  static void setHourlyRate(String projectId, double rate) {
    var rates = customHourlyRates;
    rates[projectId] = rate;
    customHourlyRates = rates;
  }

  /// Projetos que o usuário ocultou do seletor do cronômetro.
  static Set<String> get hiddenProjectIds {
    return _sp.getStringList('hidden_project_ids')?.toSet() ?? <String>{};
  }

  static void setHiddenProjectIds(Set<String> projectIds) {
    _sp.setStringList('hidden_project_ids', projectIds.toList());
  }

  static String? get lastSelectedWorkspaceId {
    return _sp.getString('last_selected_workspace_id');
  }

  static set lastSelectedWorkspaceId(String? workspaceId) {
    if (workspaceId != null) {
      _sp.setString('last_selected_workspace_id', workspaceId);
    } else {
      _sp.remove('last_selected_workspace_id');
    }
  }

  static double? get minHoursPerDay {
    return _sp.containsKey('min_hours_per_day')
        ? _sp.getDouble('min_hours_per_day')
        : null;
  }

  static set minHoursPerDay(double? value) {
    if (value != null) {
      _sp.setDouble('min_hours_per_day', value);
    } else {
      _sp.remove('min_hours_per_day');
    }
  }

  static double? get targetHoursPerDay {
    return _sp.containsKey('target_hours_per_day')
        ? _sp.getDouble('target_hours_per_day')
        : null;
  }

  static set targetHoursPerDay(double? value) {
    if (value != null) {
      _sp.setDouble('target_hours_per_day', value);
    } else {
      _sp.remove('target_hours_per_day');
    }
  }

  static String? get lastSelectedUserId {
    return _sp.getString('last_selected_user_id');
  }

  static set lastSelectedUserId(String? userId) {
    if (userId != null) {
      _sp.setString('last_selected_user_id', userId);
    } else {
      _sp.remove('last_selected_user_id');
    }
  }

  static List<TimeEntry>? getTimeEntriesFromUser({
    required String workspaceId,
    required String userId,
    required int year,
    required int month,
  }) {
    var time = '$year-${month.toString().padLeft(2, '0')}';
    var key = 'wks_$workspaceId:usr_$userId:$time';
    List<String>? list = _sp.getStringList(key);
    if (list == null) return null;
    return [for (var item in list) TimeEntry.fromJson(jsonDecode(item))];
  }

  /// Último instante do mês coberto pelo cache de entradas.
  ///
  /// Caches antigos (sem essa marca) só eram gravados para meses inteiros,
  /// então são considerados completos até o fim do mês.
  static DateTime? getTimeEntriesCachedUntil({
    required String workspaceId,
    required String userId,
    required int year,
    required int month,
  }) {
    var time = '$year-${month.toString().padLeft(2, '0')}';
    var key = 'wks_$workspaceId:usr_$userId:$time';
    if (!_sp.containsKey(key)) return null;
    var until = _sp.getString('$key:until');
    if (until == null) return DateTime(year, month + 1, 0, 23, 59, 59);
    return DateTime.parse(until);
  }

  static Future<void> setTimeEntriesForUser({
    required String workspaceId,
    required String userId,
    required int year,
    required int month,
    required List<TimeEntry>? entries,
    DateTime? cachedUntil,
  }) async {
    var time = '$year-${month.toString().padLeft(2, '0')}';
    var key = 'wks_$workspaceId:usr_$userId:$time';
    if (entries == null || !_isInTimeEntriesCacheWindow(year, month)) {
      await _sp.remove(key);
      await _sp.remove('$key:until');
      return;
    }
    await _sp.setStringList(key, [
      for (var entry in entries) jsonEncode(entry.toJson()),
    ]);
    if (cachedUntil != null) {
      await _sp.setString('$key:until', cachedUntil.toIso8601String());
    } else {
      await _sp.remove('$key:until');
    }
  }

  /// Quantos meses (contando o atual) de entradas ficam em cache.
  static const timeEntriesCacheMonths = 4;

  static final _timeEntriesKeyPattern = RegExp(
    r'^wks_.+:usr_.+:(\d{4})-(\d{2})(:until)?$',
  );

  static bool _isInTimeEntriesCacheWindow(int year, int month) {
    final now = DateTime.now();
    final monthsAgo = (now.year - year) * 12 + (now.month - month);
    return monthsAgo < timeEntriesCacheMonths;
  }

  /// Remove o cache de entradas de meses fora da janela de
  /// [timeEntriesCacheMonths], para o armazenamento não crescer sem limite.
  static Future<void> pruneTimeEntriesCache() async {
    for (final key in _sp.getKeys()) {
      final match = _timeEntriesKeyPattern.firstMatch(key);
      if (match == null) continue;
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      if (!_isInTimeEntriesCacheWindow(year, month)) {
        await _sp.remove(key);
      }
    }
  }
}
