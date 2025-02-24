import 'package:flutter/material.dart';

class PokemonSummary {
  final String name;
  final String url;
  final String imageUrl;
  final String shinyImageUrl;
  final String gifUrl;
  final String shinyGifUrl;
  final List<String> types;
  final String generation;
  final List<String> abilities;
  final double weight;
  final double height;
  final Map<String, int> stats;
  final List<Move> movesByLevel;
  final List<Move> movesByTM;
  final List<Evolution> evolutions;

  PokemonSummary({
    required this.name,
    required this.url,
    required this.imageUrl,
    required this.shinyImageUrl,
    required this.gifUrl,
    required this.shinyGifUrl,
    required this.types,
    required this.generation,
    required this.abilities,
    required this.weight,
    required this.height,
    required this.stats,
    required this.movesByLevel,
    required this.movesByTM,
    required this.evolutions,
  });

  factory PokemonSummary.fromMap(Map<String, dynamic> map) {
    final pokemonNumber = map['url'].split('/').reversed.elementAt(1);
    final imageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonNumber.png';
    final shinyImageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/$pokemonNumber.png';
    final gifUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/$pokemonNumber.gif';
    final shinyGifUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/shiny/$pokemonNumber.gif';

    final stats = <String, int>{};
    if (map['stats'] != null) {
      for (var stat in map['stats']) {
        final statName = stat['stat']['name'] as String;
        final statValue = stat['base_stat'] as int;
        stats[statName] = statValue;
      }
    }

    final movesByLevel = <Move>[];
    final movesByTM = <Move>[];
    if (map['moves'] != null) {
      for (var move in map['moves']) {
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

    return PokemonSummary(
      name: map['name'] as String,
      url: map['url'] as String,
      imageUrl: imageUrl,
      shinyImageUrl: shinyImageUrl,
      gifUrl: gifUrl,
      shinyGifUrl: shinyGifUrl,
      types: [],
      generation: '',
      abilities: [],
      weight: 0.0,
      height: 0.0,
      stats: stats,
      movesByLevel: movesByLevel,
      movesByTM: movesByTM,
      evolutions: [],
    );
  }

  String formatGeneration() {
    final romanNumeral = generation.split('-').last;
    return _generationToLocation(romanNumeral);
  }

  String _generationToLocation(String romanNumeral) {
    switch (romanNumeral.toLowerCase()) {
      case 'i':
        return 'Kanto';
      case 'ii':
        return 'Johto';
      case 'iii':
        return 'Hoenn';
      case 'iv':
        return 'Sinnoh';
      case 'v':
        return 'Unova';
      case 'vi':
        return 'Kalos';
      case 'vii':
        return 'Alola';
      case 'viii':
        return 'Galar';
      case 'ix':
        return 'Paldea';
      default:
        return 'Unknown Region';
    }
  }

  Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow;
      case 'psychic':
        return Colors.purple;
      case 'ice':
        return Colors.lightBlue;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.brown;
      case 'fairy':
        return Colors.pink;
      case 'normal':
        return Colors.grey;
      case 'fighting':
        return Colors.red;
      case 'flying':
        return Colors.lightBlue[300]!;
      case 'poison':
        return Colors.purple[300]!;
      case 'ground':
        return Colors.brown[300]!;
      case 'rock':
        return Colors.grey[600]!;
      case 'bug':
        return Colors.lightGreen[500]!;
      case 'ghost':
        return Colors.deepPurple;
      case 'steel':
        return Colors.blueGrey;
      case 'unknown':
        return Colors.grey[800]!;
      case 'shadow':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  Color getTextColorForBackground(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.light ? Colors.black : Colors.white;
  }
}

class Move {
  final String name;
  final int? levelLearned;

  Move({required this.name, this.levelLearned});
}

class Evolution {
  final String name;
  final String imageUrl;
  final String shinyImageUrl;
  final String gifUrl;
  final String shinyGifUrl;

  Evolution({
    required this.name,
    required this.imageUrl,
    required this.shinyImageUrl,
    required this.gifUrl,
    required this.shinyGifUrl,
  });
}