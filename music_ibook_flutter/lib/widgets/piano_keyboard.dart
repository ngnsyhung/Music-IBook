import 'package:flutter/material.dart';

class PianoKeyboard extends StatelessWidget {
  final void Function(String note) onPressed;
  final String? targetNote;

  const PianoKeyboard({
    super.key,
    required this.onPressed,
    this.targetNote,
  });

  @override
  Widget build(BuildContext context) {
    const notes = ['C4', 'D4', 'E4', 'F4', 'F#4', 'G4', 'A4', 'B4', 'C5', 'D5', 'E5'];

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black12,
      child: Row(
        children: notes.map((n) {
          final target = n == targetNote;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPressed(n),
              child: Container(
                height: 110,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: target ? Colors.orange : Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(n, style: const TextStyle(fontWeight: FontWeight.bold))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
