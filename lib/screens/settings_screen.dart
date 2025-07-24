import 'package:flutter/material.dart';
import 'package:leragora/utils/session_manager.dart';
import 'package:leragora/widgets/voice_selector.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkTheme = false;
  double speechRate = 0.45;
  String selectedVoice = 'female';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SessionManager.preferences;
    isDarkTheme = prefs.getBool('darkTheme') ?? false;
    speechRate = prefs.getDouble('speechRate') ?? 0.45;
    selectedVoice = prefs.getString('voice') ?? 'female';
    setState(() {});
  }

  Future<void> _savePreferences() async {
    final prefs = await SessionManager.preferences;
    await prefs.setBool('darkTheme', isDarkTheme);
    await prefs.setDouble('speechRate', speechRate);
    await prefs.setString('voice', selectedVoice);
  }

  Future<void> _logout() async {
    await _savePreferences(); // Salva antes de sair
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  void dispose() {
    _savePreferences();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Modo Escuro'),
            value: isDarkTheme,
            onChanged: (val) {
              setState(() => isDarkTheme = val);
              widget.onThemeChanged(val); // 🔄 propaga para MyApp
            },
          ),
          const SizedBox(height: 16),
          VoiceSelector(
            selectedVoice: selectedVoice,
            onChanged: (val) {
              if (val != null) {
                setState(() => selectedVoice = val);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('Velocidade da fala'),
          Slider(
            value: speechRate,
            min: 0.2,
            max: 1.0,
            divisions: 8,
            label: '${(speechRate * 100).round()}%',
            onChanged: (value) {
              setState(() => speechRate = value);
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}
