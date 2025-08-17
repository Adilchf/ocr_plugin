import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_plugin/ocr_plugin.dart'; // replace with your actual plugin

class IdCardPage extends StatefulWidget {
  const IdCardPage({super.key});

  @override
  State<IdCardPage> createState() => _IdCardPageState();
}

class _IdCardPageState extends State<IdCardPage> {
  OcrResult? _result;
  bool _loading = false;

  Future<void> _pickAndExtract() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => _loading = true);

    final file = File(pickedFile.path);
    final result = await OcrPlugin.extractData(file);

    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Card OCR")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Pick Card"),
              onPressed: _pickAndExtract,
            ),
            const SizedBox(height: 20),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_result != null && !_loading)
              Expanded(
                child: ListView(
                  children: [
                    Text("NIN: ${_result!.nin ?? '-'}"),
                    Text("Card Number: ${_result!.cardNumber ?? '-'}"),
                    Text("Family Name: ${_result!.familyName ?? '-'}"),
                    Text("Given Name: ${_result!.givenName ?? '-'}"),
                    Text("Birthdate: ${_result!.birthdate ?? '-'}"),
                    Text("Expiry Date: ${_result!.expiryDate ?? '-'}"),
                    Text("Rh: ${_result!.rhfactor ?? '-'}"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
