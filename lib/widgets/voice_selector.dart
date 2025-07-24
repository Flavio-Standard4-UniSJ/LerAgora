import 'package:flutter/material.dart';

class VoiceSelector extends StatelessWidget {
  final String selectedVoice;
  final ValueChanged<String?> onChanged;

  const VoiceSelector({
    Key? key,
    required this.selectedVoice,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Voz do audiolivro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ListTile(
          title: const Text('Feminina'),
          leading: Radio<String>(
            value: 'female',
            groupValue: selectedVoice,
            onChanged: onChanged,
          ),
        ),
        ListTile(
          title: const Text('Masculina'),
          leading: Radio<String>(
            value: 'male',
            groupValue: selectedVoice,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
