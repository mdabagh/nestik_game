import '../mafia_models.dart';
import 'mafia_data_source.dart';

// ============================================================
// Mafia Repository — دسترسی به دیتای مافیا
// ============================================================

abstract class MafiaRepository {
  Future<List<MafiaScenario>> getScenarios();
  Future<MafiaScenario?> getScenario(String id);
  Future<MafiaRole?> getRole(String id);
  Future<List<MafiaRole>> getRoles();
}

class MafiaJsonRepository implements MafiaRepository {
  final MafiaJsonDataSource _dataSource;

  MafiaData? _cache;
  Future<MafiaData>? _inFlight;

  MafiaJsonRepository({MafiaJsonDataSource? dataSource})
    : _dataSource = dataSource ?? const MafiaJsonDataSource();

  Future<MafiaData> _loadOnce() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    final pending = _inFlight;
    if (pending != null) return pending;
    final future = _dataSource
        .load()
        .then((data) {
          _cache = data;
          _inFlight = null;
          return data;
        })
        .catchError((Object e) {
          _inFlight = null;
          throw e;
        });
    _inFlight = future;
    return future;
  }

  @override
  Future<List<MafiaScenario>> getScenarios() async {
    final data = await _loadOnce();
    return List.of(data.scenarios);
  }

  @override
  Future<MafiaScenario?> getScenario(String id) async {
    final data = await _loadOnce();
    for (final s in data.scenarios) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<MafiaRole?> getRole(String id) async {
    final data = await _loadOnce();
    for (final r in data.roles) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<List<MafiaRole>> getRoles() async {
    final data = await _loadOnce();
    return List.of(data.roles);
  }
}
