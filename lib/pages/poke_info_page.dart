import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:poke_dex/models/pokemon_summary.dart';
import 'package:poke_dex/services/pokemon_service.dart';
import 'package:poke_dex/string_extention.dart';

class PokemonInfoPage extends StatefulWidget {
  final PokemonSummary pokemon;

  const PokemonInfoPage({super.key, required this.pokemon});

  @override
  _PokemonInfoPageState createState() => _PokemonInfoPageState();
}

class _PokemonInfoPageState extends State<PokemonInfoPage> {
  late Future<PokemonSummary> _pokemonDetails;
  bool _isShiny = false;
  final PokemonService _pokemonService = PokemonService();
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _pokemonDetails = _pokemonService.fetchPokemonDetails(widget.pokemon);
  }

  void _loadEvolution(String url) async {
    try {
      final response = await _dio.get(url);
      final data = response.data;
      final speciesUrl = data['species']['url'];
      final speciesResponse = await _dio.get(speciesUrl);
      final speciesData = speciesResponse.data;
      final pokemonName = speciesData['name'].toString().capitalize();

      final newPokemon = PokemonSummary.fromMap({
        'name': pokemonName,
        'url': url,
      });

      setState(() {
        _pokemonDetails = _pokemonService.fetchPokemonDetails(newPokemon);
        _isShiny = false;
      });
    } catch (e) {
      print('Erro ao carregar evolução: $e');
    }
  }

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
              color: Colors.red[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: Switch(
                    value: _isShiny,
                    onChanged: (value) {
                      setState(() {
                        _isShiny = value;
                      });
                    },
                    thumbIcon: WidgetStateProperty.resolveWith(
                      (state) {
                        if (state.contains(WidgetState.selected)) {
                          return Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 20,
                          );
                        } else {
                          return Icon(
                            Icons.star_border_outlined,
                            color: Colors.yellow,
                            size: 20,
                          );
                        }
                      },
                    ),
                    trackOutlineColor: WidgetStateProperty.resolveWith(
                      (state) {
                        if (state.contains(WidgetState.selected)) {
                          return Colors.yellow;
                        } else {
                          return Colors.transparent;
                        }
                      },
                    ),
                    activeColor: Colors.grey,
                    activeTrackColor: Colors.grey[800],
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[800],
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
                          Tab(text: 'Stats'),
                          Tab(text: 'Moves'),
                          Tab(text: 'Evolutions'),
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
    final imagUrl = _isShiny ? pokemon.shinyImageUrl : pokemon.imageUrl;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            pokemon.name.capitalize(),
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
            ),
            child: Stack(
              children: [
                _buildImage(gifUrl, imagUrl),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _buildAbilityButton(pokemon),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDescription('Weight', pokemon.weight, 'kg'),
              _buildDescription('Height', pokemon.height, 'm'),
            ],
          ),
          const SizedBox(height: 20),
          _buildTypeChips(pokemon),
        ],
      ),
    );
  }

  FutureBuilder _buildImage(String gifUrl, String imagUrl) {
    return FutureBuilder(
      future: _testGifUrl(gifUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData == false) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imagUrl,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.white, size: 50),
              ),
            );
          } else {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                gifUrl,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.white, size: 50),
              ),
            );
          }
        }
        return CircularProgressIndicator();
      },
    );
  }

  Future<Response<dynamic>?> _testGifUrl(String gifUrl) async {
    try {
      var value = await Dio().get(gifUrl);
      return Response(
          requestOptions: RequestOptions(
        data: value,
      ));
    } on DioException {
      return null;
    } catch (ex) {
      return null;
    }
  }

  Widget _buildDescription(String title, double value, String unit) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildTypeChips(PokemonSummary pokemon) {
    return Wrap(
      spacing: 8.0,
      children: pokemon.types.map((type) {
        final color = pokemon.getTypeColor(type);
        return Chip(
          backgroundColor: color,
          label: Text(
            type,
            style: TextStyle(
              color: pokemon.getTextColorForBackground(color),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAbilityButton(PokemonSummary pokemon) {
    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey[900],
        builder: (context) => SizedBox(
          height: 200,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Abilities',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 240, 240, 240),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: Colors.grey[700]!.withOpacity(0.7),
                      height: 1,
                      thickness: 1.0,
                      indent: 30,
                      endIndent: 30,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: pokemon.abilities.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      pokemon.abilities[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 240, 240, 240),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          FontAwesomeIcons.meteor,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildStatsTab(PokemonSummary pokemon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Base Stats',
            style: TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...pokemon.stats.entries.map((e) => _buildStatRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    const double iconSize = 26;
    const double labelFontSize = 9;

    final Map<String, Color> typeColors = {
      'HP': Color.fromARGB(255, 224, 224, 224),
      'ATK': Color.fromARGB(255, 224, 224, 224),
      'DEF': Color.fromARGB(255, 224, 224, 224),
      'STK': Color.fromARGB(255, 224, 224, 224),
      'SDF': Color.fromARGB(255, 224, 224, 224),
      'SPD': Color.fromARGB(255, 224, 224, 224),
    };

    final Map<String, IconData> typeIcons = {
      'HP': FontAwesomeIcons.heartPulse,
      'ATK': FontAwesomeIcons.handFist,
      'DEF': FontAwesomeIcons.shieldHalved,
      'STK': FontAwesomeIcons.fireFlameCurved,
      'SDF': FontAwesomeIcons.shieldVirus,
      'SPD': FontAwesomeIcons.bolt,
    };

    final Color dynamicColor = value < 50
        ? Colors.red[600]!
        : value < 100
            ? const Color.fromARGB(255, 255, 179, 0)
            : Colors.green[600]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(typeIcons[label]!, size: iconSize, color: typeColors[label]),
              const SizedBox(height: 2),
              Text(
                '($label)',
                style: TextStyle(
                  fontSize: labelFontSize,
                  color: typeColors[label]!.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / 150,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation(dynamicColor),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: dynamicColor,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 1.5,
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(1, 1),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovesTab(PokemonSummary pokemon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildMoveSection('Level Up Moves', pokemon.movesByLevel),
          _buildMoveSection('TM/HM Moves', pokemon.movesByTM),
        ],
      ),
    );
  }

  Widget _buildMoveSection(String title, List<Move> moves) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[200],
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: moves.map((move) => _buildMoveCard(move)).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMoveCard(Move move) {
    return InkWell(
      onTap: () => _showMoveDetails(context, move),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              move.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[100],
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                move.levelLearned != null ? 'Lv.${move.levelLearned}' : 'TM/HM',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveDetails(BuildContext context, Move move) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: _fetchMoveDetails(move.url),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final details = snapshot.data!;
          final typeColor = _getMoveTypeColor(details['type']);
          final damageClassColor = _getDamageClassColor(details['damageClass']);

          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        move.name.capitalize(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[200],
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Chip(
                          backgroundColor: typeColor,
                          label: Text(
                            details['type'].toString().toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          backgroundColor: damageClassColor,
                          label: Text(
                            details['damageClass'].toString().toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Stats Grid
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        damageClass: 'physical',
                        value: details['power']?.toString() ?? '—',
                      ),
                      _buildStatItem(
                        damageClass: 'special',
                        value: details['accuracy']?.toString() ?? '—',
                      ),
                      _buildStatItem(
                        damageClass: 'status',
                        value: details['pp']?.toString() ?? '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          details['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Additional Info
                        if (details['effect'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Effect',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[300],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                details['effect'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required String damageClass,
    required String value,
  }) {
    final (icon, color) = _getDamageClassIcon(damageClass);
    return Column(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: icon,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          damageClass.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Color _getMoveTypeColor(String type) {
    final typeColors = {
      'normal': Colors.grey[400]!,
      'fire': Colors.orange[600]!,
      'water': Colors.blue[400]!,
      'electric': Colors.yellow[600]!,
      'grass': Colors.green[400]!,
      'ice': Colors.cyan[300]!,
      'fighting': Colors.red[700]!,
      'poison': Colors.purple[400]!,
      'ground': Colors.amber[700]!,
      'flying': Colors.indigo[300]!,
      'psychic': Colors.pink[400]!,
      'bug': Colors.lightGreen[500]!,
      'rock': Colors.brown[500]!,
      'ghost': Colors.indigo[800]!,
      'dragon': Colors.deepPurple[400]!,
      'dark': Colors.brown[900]!,
      'steel': Colors.blueGrey[400]!,
      'fairy': Colors.pink[200]!,
    };
    return typeColors[type.toLowerCase()] ?? Colors.grey;
  }

  (Widget, Color) _getDamageClassIcon(String damageClass) {
    switch (damageClass.toLowerCase()) {
      case 'physical':
        return (
          SvgPicture.asset(
            'assets/icons/physical.svg',
            width: 28,
            colorFilter: ColorFilter.mode(Colors.red[400]!, BlendMode.srcIn),
          ),
          Colors.red[400]!
        );
      case 'special':
        return (
          SvgPicture.asset(
            'assets/icons/special.svg',
            width: 28,
            colorFilter: ColorFilter.mode(Colors.blue[400]!, BlendMode.srcIn),
          ),
          Colors.blue[400]!
        );
      case 'status':
        return (
          SvgPicture.asset(
            'assets/icons/status.svg',
            width: 28,
            colorFilter: ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn),
          ),
          Colors.grey[400]!
        );
      default:
        return (
          Icon(Icons.help_outline, size: 28, color: Colors.grey),
          Colors.grey
        );
    }
  }

  Color _getDamageClassColor(String damageClass) {
    switch (damageClass.toLowerCase()) {
      case 'physical':
        return Colors.red[400]!;
      case 'special':
        return Colors.blue[400]!;
      case 'status':
        return Colors.grey[400]!;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>> _fetchMoveDetails(String url) async {
    try {
      final moveId = url.split('/').reversed.elementAt(1);
      final response =
          await Dio().get('https://pokeapi.co/api/v2/move/$moveId/');
      final data = response.data;

      final flavorTexts = (data['flavor_text_entries'] as List)
          .where((entry) => entry['language']['name'] == 'en')
          .toList();

      final effectEntries = (data['effect_entries'] as List)
          .where((entry) => entry['language']['name'] == 'en')
          .toList();

      return {
        'type': data['type']['name'],
        'power': data['power'],
        'accuracy': data['accuracy'],
        'pp': data['pp'],
        'damageClass': data['damage_class']['name'],
        'description': flavorTexts.isNotEmpty
            ? flavorTexts.last['flavor_text'].toString().replaceAll('\n', ' ')
            : 'No description available',
        'effect': effectEntries.isNotEmpty
            ? effectEntries.first['effect'].toString().replaceAll('\n', ' ')
            : null,
      };
    } catch (e) {
      return {
        'type': 'unknown',
        'power': null,
        'accuracy': null,
        'pp': null,
        'damageClass': 'unknown',
        'description': 'Failed to load move details',
        'effect': null,
      };
    }
  }

  Future<String> _fetchMoveDescription(String url) async {
    try {
      final moveId = url.split('/').reversed.elementAt(1);
      final response =
          await Dio().get('https://pokeapi.co/api/v2/move/$moveId/');
      final data = response.data;

      final flavorTexts = (data['flavor_text_entries'] as List)
          .where((entry) => entry['language']['name'] == 'en')
          .toList();

      if (flavorTexts.isNotEmpty) {
        return flavorTexts.last['flavor_text'].toString().replaceAll('\n', ' ');
      }
      return 'No description available';
    } catch (e) {
      return 'Failed to load description';
    }
  }

  Widget _buildEvolutionsTab(PokemonSummary pokemon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Evolution',
            style: TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (pokemon.evolutions.isEmpty)
            const Text(
              'This Pokémon does not evolve.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          if (pokemon.evolutions.isNotEmpty)
            _buildEvolutionTree(pokemon.evolutions),
        ],
      ),
    );
  }

  Widget _buildEvolutionTree(List<Evolution> evolutions) {
    return Column(
      children: evolutions
          .map((evolution) => _buildEvolutionChain(evolution))
          .toList(),
    );
  }

  Widget _buildEvolutionChain(Evolution evolution) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          _buildEvolutionCard(evolution),
          if (evolution.nextEvolutions.isNotEmpty) ...[
            const Icon(Icons.arrow_downward, color: Colors.white54, size: 32),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: evolution.nextEvolutions
                  .map((nextEvo) => _buildEvolutionChain(nextEvo))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvolutionCard(Evolution evolution) {
    final gifUrl = _isShiny ? evolution.shinyGifUrl : evolution.gifUrl;
    return InkWell(
      onTap: () => _loadEvolution(evolution.url),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850]!.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Image.network(
                gifUrl,
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.red[800],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.error_outline,
                  color: Colors.grey[800],
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              evolution.name,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (evolution.trigger != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  evolution.trigger!,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
