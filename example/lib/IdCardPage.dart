import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_plugin/ocr_plugin.dart'; // your plugin

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

    try {
      final file = File(pickedFile.path);

      // Plan A: try with face detection first
      OcrResult res;
      try {
        res = await OcrPlugin.extractData(file, detectAndCropFace: true);
      } catch (_) {
        // If face path fails / no face: retry without face detection
        res = await OcrPlugin.extractData(file, detectAndCropFace: false);
      }

      if (!mounted) return;
      setState(() => _result = res);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _result != null && !_loading;
    final hasFace = hasResult && (_result!.facePath ?? '').isNotEmpty;

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
                    _kv('NIN', _result!.nin),
                    _kv('Card Number', _result!.cardNumber),
                    _kv('Family Name', _result!.familyName),
                    _kv('Given Name', _result!.givenName),
                    _kv('Birthdate', _result!.birthdate),
                    _kv('Expiry Date', _result!.expiryDate),
                    _kv('Rh', _result!.rhfactor),
                    _kv('NIF', _result!.nif),
                    _kv('Raison Sociale', _result!.societyName),
                    _kv('Passport Card Number', _result!.cardNumberPassport),
                    _kv('Passport Family Name', _result!.familyNamePassport),

                    // --- Only show photo if a face was detected ---
                    if (hasFace) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Extracted Photo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_result!.facePath!),
                            height: 30,
                            width: 30,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String? value) {
    if ((value ?? '').isEmpty) return const SizedBox.shrink();
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
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}
