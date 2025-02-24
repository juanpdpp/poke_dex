import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:poke_dex/models/pokemon_summary.dart';

class PokemonInfoPage extends StatefulWidget {
  final PokemonSummary pokemon;

  const PokemonInfoPage({super.key, required this.pokemon});

  @override
  _PokemonInfoPageState createState() => _PokemonInfoPageState();
}

class _PokemonInfoPageState extends State<PokemonInfoPage> {
  late Future<PokemonSummary> _pokemonDetails;
  bool _isShiny = false;

  @override
  void initState() {
    super.initState();
    _pokemonDetails = _fetchPokemonDetails(widget.pokemon);
  }

  Future<PokemonSummary> _fetchPokemonDetails(PokemonSummary pokemon) async {
    try {
      final dio = Dio();
      final response = await dio.get(pokemon.url);

      if (response.statusCode == 200) {
        final data = response.data;

        final types = (data['types'] as List)
            .map((type) => (type['type']['name'] as String).toUpperCase())
            .toList();

        final abilities = (data['abilities'] as List)
            .map((ability) => ability['ability']['name'] as String)
            .toList();

        final speciesResponse = await dio.get(data['species']['url']);
        final speciesData = speciesResponse.data;
        final generation = speciesData['generation']['name'] as String;

        final weight = (data['weight'] as int) / 10.0;
        final height = (data['height'] as int) / 10.0;

        final stats = <String, int>{};
        if (data['stats'] != null) {
          for (var stat in data['stats']) {
            final statName = stat['stat']['name'] as String;
            final statValue = stat['base_stat'] as int;
            stats[statName] = statValue;
          }
        }

        final movesByLevel = <Move>[];
        final movesByTM = <Move>[];
        if (data['moves'] != null) {
          for (var move in data['moves']) {
            final moveName = move['move']['name'] as String;
            final moveDetails = move['version_group_details'] as List;
            for (var detail in moveDetails) {
              final method = detail['move_learn_method']['name'] as String;
              if (method == 'level-up') {
                final levelLearned = detail['level_learned_at'] as int;
                if (!movesByLevel.any((m) => m.name == moveName)) {
                  movesByLevel
                      .add(Move(name: moveName, levelLearned: levelLearned));
                }
              } else if (method == 'machine') {
                if (!movesByTM.any((m) => m.name == moveName)) {
                  movesByTM.add(Move(name: moveName));
                }
              }
            }
          }
        }

        movesByLevel.sort(
            (a, b) => (a.levelLearned ?? 0).compareTo(b.levelLearned ?? 0));
        movesByTM.sort((a, b) => a.name.compareTo(b.name));

        final evolutionChainUrl =
            speciesData['evolution_chain']['url'] as String;
        final evolutionResponse = await dio.get(evolutionChainUrl);
        final evolutionData = evolutionResponse.data;

        final evolutions = <Evolution>[];
        _parseEvolutionChain(evolutionData['chain'], evolutions);

        return PokemonSummary(
          name: pokemon.name,
          url: pokemon.url,
          imageUrl: pokemon.imageUrl,
          shinyImageUrl: pokemon.shinyImageUrl,
          gifUrl: pokemon.gifUrl,
          shinyGifUrl: pokemon.shinyGifUrl,
          types: types,
          generation: generation,
          abilities: abilities,
          weight: weight,
          height: height,
          stats: stats,
          movesByLevel: movesByLevel,
          movesByTM: movesByTM,
          evolutions: evolutions, // Lista de evoluções
        );
      } else {
        throw Exception('Failed to load Pokémon details');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  void _parseEvolutionChain(
      Map<String, dynamic> chain, List<Evolution> evolutions) {
    final species = chain['species'];
    final name = species['name'] as String;
    final id = _extractPokemonNumber(species['url'] as String);
    final imageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
    final shinyImageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/$id.png';
    final gifUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/$id.gif';
    final shinyGifUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/shiny/$id.gif';

    evolutions.add(Evolution(
      name: name,
      imageUrl: imageUrl,
      shinyImageUrl: shinyImageUrl,
      gifUrl: gifUrl,
      shinyGifUrl: shinyGifUrl,
    ));

    if (chain['evolves_to'] != null && chain['evolves_to'].isNotEmpty) {
      for (var evolution in chain['evolves_to']) {
        _parseEvolutionChain(evolution, evolutions);
      }
    }
  }

  int _extractPokemonNumber(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    return int.parse(segments[segments.length - 2]);
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red[800]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.yellow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 1.1,
                  child: Switch(
                    value: _isShiny,
                    onChanged: (value) {
                      setState(() {
                        _isShiny = value;
                      });
                    },
                    activeColor: Colors.red[800],
                    activeTrackColor: Colors.red[800]!.withOpacity(0.5),
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder<PokemonSummary>(
        future: _pokemonDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          }

          final pokemon = snapshot.data!;

          return Column(
            children: [
              _buildPokemonHeader(pokemon),
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: const [
                          Tab(text: 'Estatisticas'),
                          Tab(text: 'Movimentos'),
                          Tab(text: 'Evoluções'),
                        ],
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildStatsTab(pokemon),
                            _buildMovesTab(pokemon),
                            _buildEvolutionsTab(pokemon),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPokemonHeader(PokemonSummary pokemon) {
    final gifUrl = _isShiny ? pokemon.shinyGifUrl : pokemon.gifUrl;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _capitalize(pokemon.name),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                gifUrl,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.white, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDescriptionPoekmonData('Peso', pokemon.weight, 'kg'),
              _buildDescriptionPoekmonData('Altura', pokemon.height, 'm'),
              _buttonModalBottomSheetHabilidades(pokemon),
            ],
          ),
          const SizedBox(height: 20),
          _buildWrapPokemonTipoDescriptions(pokemon),
        ],
      ),
    );
  }

  Column _buildDescriptionPoekmonData(
      String titulo, double number, String unidadeMedida) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        Text(
          '$number $unidadeMedida',
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Wrap _buildWrapPokemonTipoDescriptions(PokemonSummary pokemon) {
    return Wrap(
      spacing: 8.0,
      children: pokemon.types.map((type) {
        final backgroundColor = pokemon.getTypeColor(type);
        final textColor = pokemon.getTextColorForBackground(backgroundColor);
        return Chip(
          backgroundColor: backgroundColor,
          side: BorderSide.none,
          label: Text(
            type,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  ElevatedButton _buttonModalBottomSheetHabilidades(PokemonSummary pokemon) {
    return ElevatedButton.icon(
      label: Icon(Icons.ac_unit),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'Habilidades',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: pokemon.abilities.map((ability) {
                        return Text(
                          _capitalize(ability),
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsTab(PokemonSummary pokemon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              _buildStatRow('HP', pokemon.stats['hp'] ?? 0),
              _buildStatRow('ATK', pokemon.stats['attack'] ?? 0),
              _buildStatRow('DEF', pokemon.stats['defense'] ?? 0),
              _buildStatRow('STK', pokemon.stats['special-attack'] ?? 0),
              _buildStatRow('SEF', pokemon.stats['special-defense'] ?? 0),
              _buildStatRow('SPD', pokemon.stats['speed'] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovesTab(PokemonSummary pokemon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Movimentos Aprendidos por Nível',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ...pokemon.movesByLevel.map((move) {
            return ListTile(
              title: Text(
                '${move.name} (Nível ${move.levelLearned})',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          const Text(
            'Movimentos Aprendidos por TM',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ...pokemon.movesByTM.map((move) {
            return ListTile(
              title: Text(
                move.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEvolutionsTab(PokemonSummary pokemon) {
    final evolutions = pokemon.evolutions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Evoluções',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          if (evolutions.isEmpty)
            const Text(
              'Este Pokémon não possui evoluções.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          if (evolutions.isNotEmpty)
            Column(
              children: evolutions.map((evolution) {
                return Column(
                  children: [
                    _buildEvolutionCard(evolution),
                    if (evolution != evolutions.last)
                      const Column(
                        children: [
                          SizedBox(height: 10),
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEvolutionCard(Evolution evolution) {
    final gifUrl = _isShiny ? evolution.shinyGifUrl : evolution.gifUrl;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              gifUrl,
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, color: Colors.white, size: 50),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _capitalize(evolution.name),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int value) {
    Color progressColor;

    if (value < 50) {
      progressColor = Colors.red;
    } else if (value < 100) {
      progressColor = Colors.yellow;
    } else {
      progressColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 150,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
