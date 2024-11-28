import '../../pokemon/models/data/pokemon.dart';
import '../../pokemon/models/data/pokemon_api_model.dart';
import '../models/data_sources/data_source.dart';

/// DemoHacksHelper represents a singleton helper for adding few demo hacks to
/// the code, so that for instance every time I refresh I'm able to retrieve 1
/// pokemon more than the ones I have locally; this mocks the behaviour of
/// the data model being shared between two instances of the app on two
/// devices, or alternatively the app being a pokedex shared between two
/// players. Everything inside this class can be considered a demo hack
class DemoHacksHelper {
  static final instance = DemoHacksHelper._internal();

  // internal constructor
  DemoHacksHelper._internal();

  static const _defaultLowestId = 1;
  static const _defaultHighestId = 0;

  int _lowestId = _defaultLowestId;
  int get lowestId => _lowestId;
  int _highestId = _defaultHighestId;
  int get highestId => _highestId;

  late final DataSource<PokemonApiModel> _local;
  late final DataSource<PokemonApiModel> _remote;

  final bool _showError = false;
  final bool _artificialDelay = true;

  Future<void> artificialDelay(int ms) async {
    if (_artificialDelay) {
      await Future.delayed(Duration(milliseconds: ms));
    }
  }

  void error() {
    if (_showError) {
      throw Exception('Flutter Vikings poor internet connection');
    }
  }

  void setDataSources(
      DataSource<PokemonApiModel> local, DataSource<PokemonApiModel> remote) {
    _local = local;
    _remote = remote;
  }

  void resetLocal() async {
    await _local.createAll([]);
  }

  void updateIds(List<PokemonApiModel> pokemon) {
    _lowestId = pokemon.isEmpty ? 1 : pokemon.first.id;
    _highestId = pokemon.isEmpty ? 0 : pokemon.last.id;
  }

  Future<Pokemon?> nextPokemonFromRemote() async {
    try {
      final model = await _remote.read(_highestId + 1);
      return model == null ? null : Pokemon.fromPokemonApiModel(model);
    } on Exception catch (_) {
      return null;
    }
  }

  Future<Pokemon?> firstPokemonFromLocal() async {
    try {
      final models = await _local.readAll();
      return models.isEmpty ? null : Pokemon.fromPokemonApiModel(models.first);
    } on Exception catch (_) {
      return null;
    }
  }
}
