import 'package:flutter/material.dart';
import 'package:ocr_plugin_example/AttestationFiscale.dart';
import 'package:ocr_plugin_example/IdCardPage.dart';
import 'package:ocr_plugin_example/PassportPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document OCR',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Document Type")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("ID Card / Driving License"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IdCardPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Passport"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PassportPage()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Attestation D'Immatriculation Fiscale"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Attestationfiscale(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
