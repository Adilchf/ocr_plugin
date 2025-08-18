import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_plugin/ocr_plugin.dart'; // replace with your actual plugin

class Attestationfiscale extends StatefulWidget {
  const Attestationfiscale({super.key});

  @override
  State<Attestationfiscale> createState() => _AttestationfiscaleState();
}

class _AttestationfiscaleState extends State<Attestationfiscale> {
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
    final hasResult = _result != null && !_loading;
    final hasFace =
        hasResult && _result!.facePath != null && _result!.facePath!.isNotEmpty;

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

            if (hasResult)
              Expanded(
                child: ListView(
                  children: [
                    // --- Extracted data ---
                    _kv('NIF', _result!.nif),
                    _kv('Raison Sociale', _result!.societyName),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // --- Cropped face photo printed BELOW the data ---
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
