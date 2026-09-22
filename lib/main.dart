import 'package:flutter/material.dart';
import 'screens/programmer_screen.dart';

void main() {
  runApp(const RomanceClubApp());
}

class RomanceClubApp extends StatelessWidget {
  const RomanceClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Клуб Романтики',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Клуб Романтики',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Text(
              'Леди Баг и Супер-Кот',
              style: TextStyle(
                fontSize: 32,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 67),
            
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'Играть',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgrammerScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'Режим разработчика',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}