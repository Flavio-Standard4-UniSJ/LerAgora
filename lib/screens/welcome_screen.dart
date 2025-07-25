import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const WelcomeScreen({super.key, this.onThemeChanged});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _acceptedPrivacy = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyAccepted();
  }

  Future<void> _checkPrivacyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('accepted_privacy') ?? false;
    setState(() {
      _acceptedPrivacy = accepted;
    });
  }

  Future<void> _acceptPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_privacy', true);
    setState(() {
      _acceptedPrivacy = true;
    });
  }

  Future<void> _launchPrivacyPolicy() async {
    const url = 'https://flavio-standard4-unisj.github.io/LerAgora/';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a política.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', height: 120),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),

          if (!_acceptedPrivacy)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black.withOpacity(0.85),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Ao continuar, você concorda com nossa ',
                          style: const TextStyle(color: Colors.white),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: _launchPrivacyPolicy,
                                child: const Text(
                                  'política de privacidade',
                                  style: TextStyle(
                                    color: Colors.lightBlueAccent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _acceptPrivacyPolicy,
                      child: const Text(
                        'OK',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
