import 'dart:async';

import 'package:flutter_arch_comp/src/core/models/repositories/repository.dart';

import '../../../core/models/data_sources/data_source.dart';
import '../../../core/utils/demo_hacks_helper.dart';
import '../../../network/utils/connectivity.dart';
import '../data/pokemon.dart';
import '../data/pokemon_api_model.dart';

/// PokemonRepository represents a [Repository] for pokemon. For more
/// information on repositories, see
/// https://developer.android.com/jetpack/guide/data-layer
class PokemonRepository implements Repository<Pokemon> {
  PokemonRepository(this._local, this._remote, this._connectivity) {
    // this is a demo hack
    DemoHacksHelper.instance.setDataSources(_local, _remote);
  }
  final DataSource<PokemonApiModel> _local;
  final DataSource<PokemonApiModel> _remote;
  final Connectivity _connectivity;
  final _streamController =
      StreamController<List<Pokemon>>.broadcast(sync: true);

  @override
  Stream<Pokemon?> watch(int id) {
    return _streamController.stream.map((pokemon) {
      final one =
          pokemon.firstWhere((p) => p.id == id, orElse: () => const Pokemon());
      return one.isEmpty ? null : one;
    });
  }

  @override
  Stream<List<Pokemon>> watchAll() {
    return _streamController.stream;
  }

  @override
  Future<void> create(Pokemon pokemon) async {
    // TODO(alesalv): remove artificial delay
    await DemoHacksHelper.instance.artificialDelay(3000);

    // TODO(alesalv): remove error
    DemoHacksHelper.instance.error();

    if (await _connectivity.isConnected()) {
      try {
        final model = pokemon.toPokemonApiModel();
        await _remote.create(model);
        await _local.create(model);
        final models = await _local.readAll();
        _streamController
            .add(models.map((m) => Pokemon.fromPokemonApiModel(m)).toList());
      } on Exception catch (e) {
        throw Exception('Unable to create pokemon with id ${pokemon.id}, $e');
      }
    } else {
      // here an offline first approach should be implemented, out of the
      // scope for this demo
      throw UnimplementedError('Not supported for this demo');
    }
  }

  @override
  Future<Pokemon?> read(int id) async {
    // TODO(alesalv): remove artificial delay
    await DemoHacksHelper.instance.artificialDelay(3000);

    if (await _connectivity.isConnected()) {
      try {
        final model = await _local.read(id);
        return model == null ? null : Pokemon.fromPokemonApiModel(model);
      } on Exception catch (e) {
        throw Exception('Unable to read pokemon with id $id, $e');
      }
    } else {
      throw UnimplementedError('Not supported for this demo');
    }
  }

  @override
  Future<List<Pokemon>> readAll() async {
    // TODO(alesalv): remove artificial delay
    await DemoHacksHelper.instance.artificialDelay(1);

    if (await _connectivity.isConnected()) {
      try {
        final models = await _local.readAll();
        return models.map((m) => Pokemon.fromPokemonApiModel(m)).toList();
      } on Exception catch (e) {
        throw Exception('Unable to read pokemon, $e');
      }
    } else {
      throw UnimplementedError('Not supported for this demo');
    }
  }

  @override
  Future<void> update(Pokemon pokemon) async {
    // TODO(alesalv): remove artificial delay
    await DemoHacksHelper.instance.artificialDelay(3000);

    if (await _connectivity.isConnected()) {
      try {
        final model = pokemon.toPokemonApiModel();
        await _remote.update(model);
        await _local.update(model);
        final models = await _local.readAll();
        _streamController
            .add(models.map((m) => Pokemon.fromPokemonApiModel(m)).toList());
      } on Exception catch (e) {
        throw Exception('Unable to update pokemon with id ${pokemon.id}, $e');
      }
    } else {
      throw UnimplementedError('Not supported for this demo');
    }
  }

  @override
  Future<void> delete(int id) async {
    // TODO(alesalv): remove artificial delay
    await DemoHacksHelper.instance.artificialDelay(3000);

    if (await _connectivity.isConnected()) {
      try {
        await _remote.delete(id);
        await _local.delete(id);
        final models = await _local.readAll();
        _streamController
            .add(models.map((m) => Pokemon.fromPokemonApiModel(m)).toList());
      } on Exception catch (e) {
        throw Exception('Unable to delete pokemon with id $id, $e');
      }
    } else {
      throw UnimplementedError('Not supported for this demo');
    }
  }

  @override
  Future<void> refresh() async {
    // TODO(alesalv): remove artificial delay
    await DemoHacksHelper.instance.artificialDelay(3000);

    if (await _connectivity.isConnected()) {
      try {
        final remotePokemon = await _remote.readAll();
        // persist into local db
        await _local.createAll(remotePokemon);
        final models = await _local.readAll();
        _streamController
            .add(models.map((m) => Pokemon.fromPokemonApiModel(m)).toList());
      } on Exception catch (e) {
        throw Exception('Unable to refresh pokemon, $e');
      }
    } else {
      throw UnimplementedError('Not supported for this demo');
    }
  }

  @override
  void dispose() {
    if (!_streamController.hasListener) {
      _streamController.close();
    }
  }
}
