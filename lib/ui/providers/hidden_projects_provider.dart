// Provider com os projetos ocultados pelo usuário no seletor do cronômetro.
import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// IDs dos projetos que NÃO devem aparecer no seletor do cronômetro.
///
/// A lista é persistida no LocalStorage, então vale entre sessões. Projetos
/// novos aparecem normalmente: só entra aqui o que o usuário ocultar.
final hiddenProjectIdsProvider =
    StateNotifierProvider<HiddenProjectIdsNotifier, Set<String>>((ref) {
      return HiddenProjectIdsNotifier();
    });

class HiddenProjectIdsNotifier extends StateNotifier<Set<String>> {
  HiddenProjectIdsNotifier() : super(LocalStorageModule.hiddenProjectIds);

  bool isHidden(String projectId) => state.contains(projectId);

  void setHidden(String projectId, bool hidden) {
    final next = {...state};
    if (hidden) {
      next.add(projectId);
    } else {
      next.remove(projectId);
    }
    state = next;
    LocalStorageModule.setHiddenProjectIds(next);
  }

  void toggle(String projectId) => setHidden(projectId, !isHidden(projectId));

  void showAll() {
    state = <String>{};
    LocalStorageModule.setHiddenProjectIds(state);
  }
}
