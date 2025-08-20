import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_plugin/ocr_plugin.dart';
import 'package:ocr_plugin_example/services/ocr_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Document OCR",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DocumentPage(),
    );
  }
}

class DocumentPage extends StatefulWidget {
  const DocumentPage({super.key});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  final picker = ImagePicker();
  OcrResult? _localResult; // plugin result
  Map<String, dynamic>? _serverResult; // server result
  bool _loading = false;
  String? _currentDoc;

  Future<void> _pickAndExtract({required String docType}) async {
    setState(() {
      _currentDoc = docType;
      _localResult = null;
      _serverResult = null;
    });

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => _loading = true);

    try {
      final file = File(pickedFile.path);

      // Local OCR
      final localRes = await OcrPlugin.extractData(file);

      // Server OCR
      final serverRes = await ServerOcrService.extractFromServer(file, docType);

      if (!mounted) return;
      setState(() {
        _localResult = localRes;
        _serverResult = serverRes;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyResult =
        (_localResult != null || _serverResult != null) && !_loading;

    return Scaffold(
      appBar: AppBar(title: const Text("Select Document Type")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              child: const Text("ID Card / Driving License"),
              onPressed: () => _pickAndExtract(docType: "ID Card"),
            ),
            ElevatedButton(
              child: const Text("Passport"),
              onPressed: () => _pickAndExtract(docType: "Passport"),
            ),
            ElevatedButton(
              child: const Text("Attestation Fiscale"),
              onPressed: () => _pickAndExtract(docType: "Attestation Fiscale"),
            ),
            ElevatedButton(
              child: const Text("Certificat d'Existence"),
              onPressed: () =>
                  _pickAndExtract(docType: "Certificat d'Existence"),
            ),
            ElevatedButton(
              child: const Text("Registre Commerce"),
              onPressed: () => _pickAndExtract(docType: "Registre Commerce"),
            ),
            ElevatedButton(
  child: const Text("Birth Certificate"),
  onPressed: () => _pickAndExtract(docType: "Birth Certificate"),
),
ElevatedButton(
  child: const Text("Residence Certificate"),
  onPressed: () => _pickAndExtract(docType: "Residence Certificate"),
),

            const SizedBox(height: 20),

            if (_loading) const CircularProgressIndicator(),

            if (hasAnyResult)
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      "Results for $_currentDoc",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(height: 20),

                    // Local OCR
                    if (_localResult != null &&
            _currentDoc != "Birth Certificate" &&
            _currentDoc != "Residence Certificate") ...[
                      Text("📌 Local OCR",
                          style: Theme.of(context).textTheme.titleSmall),
                      ..._buildDocFields(_currentDoc!, _localResult!),
                      const SizedBox(height: 20),
                    ],

                    // Server OCR
                    if (_serverResult != null) ...[
                      Text("🌍 Server OCR",
                          style: Theme.of(context).textTheme.titleSmall),
                      ..._serverResult!.entries.map((e) => _kv(e.key, e.value)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Local OCR specific fields
  List<Widget> _buildDocFields(String docType, OcrResult res) {
    switch (docType) {
      case "ID Card":
        return [
          _kv("NIN", res.nin),
          _kv("Card Number", res.cardNumber),
          _kv("Family Name", res.familyName),
          _kv("Given Name", res.givenName),
          _kv("Birthdate", res.birthdate),
          _kv("Expiry Date", res.expiryDate),
          _kv("Rh", res.rhfactor),
        ];
      case "Passport":
        return [
          _kv("NIN", res.nin),
          _kv("Passport Number", res.cardNumberPassport),
          _kv("Family Name", res.familyNamePassport),
          _kv("Given Name", res.givenName),
          _kv("Birthdate", res.birthdate),
          _kv("Expiry Date", res.expiryDate),
          _kv("Authority", res.authority),
        ];
      case "Attestation Fiscale":
        return [_kv("NIF", res.nif), _kv("Raison Sociale", res.societyName)];
      case "Certificat d'Existence":
        return [
          _kv("BP", res.bp),
          _kv("Article Number", res.articleNumber),
          _kv("RCN", res.rcn),
        ];
      case "Registre Commerce":
        return [_kv("RCN", res.rcnarab)];
      default:
        return [const Text("No specific fields configured")];
    }
  }

  Widget _kv(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
