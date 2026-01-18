import 'package:flutter/material.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: .8,
        child: Row(
          spacing: 20,
          children: [
            Icon(Icons.timer, size: 40),
            Expanded(
              child: TextField(
                decoration: InputDecoration(labelText: 'Descrição'),
              ),
            ),
            TextButton(onPressed: () {}, child: Text('Começar')),
          ],
        ),
      ),
    );
  }
}
