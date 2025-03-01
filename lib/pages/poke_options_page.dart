import 'package:flutter/material.dart';

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  bool _isDarkMode = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Português'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Options'),
        backgroundColor: Colors.red[800],
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dark Mode Switch
            ListTile(
              title: const Text(
                'Dark Mode',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  // botar a logica de mudar o temaaqui
                },
                activeTrackColor: Colors.red[200],
                activeColor: Colors.red[800],
              ),
            ),

            // Language Selection
            ListTile(
              title: const Text(
                'Language',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                  });
                  //logica genial pra mudar a merdad od idioma
                },
                items: _languages.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
