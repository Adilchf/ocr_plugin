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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
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
  OcrResult? _localResult;
  Map<String, dynamic>? _serverResult;
  bool _loading = false;
  String? _currentDoc;

  Future<void> _pickAndExtract({required String docType}) async {
    setState(() {
      _localResult = null;
      _serverResult = null;
       _currentDoc = docType;
    });

    // choose camera/gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.indigo),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.indigo),
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

      // local OCR
      OcrResult? localRes;
      if (docType != "Birth Certificate" && docType != "Residence Certificate") {
        localRes = await OcrPlugin.extractData(file);
      }

      // server OCR
      Map<String, dynamic>? serverRes;
      if (docType == "Birth Certificate" || docType == "Residence Certificate") {
        serverRes = await ServerOcrService.extractFromServer(file, docType);
      }

      if (!mounted) return;
      setState(() {
        _localResult = localRes;
        _serverResult = serverRes;
      });

      // popup styled dialog
      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Results",
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📄 Results for $docType",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        if (_localResult != null) ...[
                          const Text("Extracted Data ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo)),
                          ..._buildDocFields(docType, _localResult!),
                          const SizedBox(height: 12),
                        ],
                        if (_serverResult != null) ...[
                          const Text("Extracted Data",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo)),
                                  if (_currentDoc == "Residence Certificate") ...[
    
    _kv("Birth Place", _serverResult!["arabic"]?["birthPlace"]),
    _kv("Address", _serverResult!["arabic"]?["address"]),
    _kv("Commune", _serverResult!["arabic"]?["commune"]),
  ] else if (_currentDoc == "Birth Certificate") ...[
    
    _kv("Father Full Name", _serverResult!["arabic"]?["fatherFullName"]),
    _kv("Mother Full Name", _serverResult!["arabic"]?["motherFullName"]),
    _kv("Birth Certificate Number", _serverResult!["arabic"]?["birthCertificateNumber"]),
  ] else
                          ..._serverResult!.entries.map((e) => _kv(e.key, e.value)),
                        ],
                        if (_localResult == null && _serverResult == null)
                          const Text("⚠️ No data extracted"),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close",
                                style: TextStyle(color: Colors.white)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (_, anim, __, child) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: child,
            );
          },
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Document OCR"),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _docCard("ID Card (Front)", "ID Card", Icons.credit_card),
            _docCard("ID Card (Back)", "ID Card", Icons.credit_card),
            _docCard("Passport", "Passport", Icons.travel_explore),

            _docCard("Birth Certificate", "Birth Certificate", Icons.child_care),
            _docCard("Residence Certificate", "Residence Certificate", Icons.home),
            if (_loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator(color: Colors.indigo)),
            ]
          ],
        ),
      ),
    );
  }

  /// Card UI for each doc
  Widget _docCard(String label, String docType, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(icon, color: Colors.indigo),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ]),
            ElevatedButton.icon(
              onPressed: () => _pickAndExtract(docType: docType),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text("Upload"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Local OCR fields
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
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
