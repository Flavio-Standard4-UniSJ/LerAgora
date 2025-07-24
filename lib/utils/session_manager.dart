import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUsername = 'loggedInUser';

  /// Salva o nome do usuário logado
  static Future<void> saveUserSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

  /// Limpa a sessão (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
  }

  /// Recupera o usuário logado ou null
  static Future<String?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  /// Acesso direto às SharedPreferences, útil para configurações
  static Future<SharedPreferences> get preferences async {
    return await SharedPreferences.getInstance();
  }
}
