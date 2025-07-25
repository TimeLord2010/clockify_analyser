import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
