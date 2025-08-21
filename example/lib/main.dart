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

  // Track confirmed documents
  final Set<String> _confirmedDocs = {};

  // Required document list
  final List<String> _requiredDocs = [
    "ID Card Front",
    "ID Card Back",
    "Birth Certificate",
    "Residence Certificate"
  ];

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
                        if (_localResult != null)
                          ..._buildDocFields(docType, _localResult!),
                        if (_serverResult != null) ...[
                          if (_currentDoc == "Residence Certificate") ...[
                            _kv("Full Name", _serverResult!["arabic"]?["fullName"]),
                            _kv("Birth Place", _serverResult!["arabic"]?["birthPlace"]),
                            _kv("Address", _serverResult!["arabic"]?["address"]),
                            _kv("Wilaya", _serverResult!["arabic"]?["wilaya"]),
                          ] else if (_currentDoc == "Birth Certificate") ...[
                            _kv("Father Full Name", _serverResult!["arabic"]?["fatherFullName"]),
                            _kv("Mother Full Name", _serverResult!["arabic"]?["motherFullName"]),
                            _kv("Birth Certificate Number",
                                _serverResult!["arabic"]?["birthCertificateNumber"]),
                          ],
                        ],
                        if (_localResult == null && _serverResult == null)
                          const Text("⚠️ No data extracted"),
                        const SizedBox(height: 16),

                        // Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_currentDoc != null) {
                                    _confirmedDocs.add(_currentDoc!);
                                  }
                                });
                                Navigator.pop(context);
                              },
                              child: const Text("Confirm"),
                            ),
                          ],
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
    final allConfirmed =
        _requiredDocs.every((doc) => _confirmedDocs.contains(doc));

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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _docCard("ID Card (Front)", "ID Card Front", Icons.credit_card),
                  _docCard("ID Card (Back)", "ID Card Back", Icons.credit_card),
                  _docCard("Birth Certificate", "Birth Certificate", Icons.child_care),
                  _docCard("Residence Certificate", "Residence Certificate", Icons.home),
                  if (_loading) ...[
                    const SizedBox(height: 20),
                    const Center(
                        child: CircularProgressIndicator(color: Colors.indigo)),
                  ]
                ],
              ),
            ),

            // Continue button only when all are confirmed
            if (allConfirmed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ All documents confirmed!")),
                    );
                    // Navigate to next page here
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  /// Card UI for each doc
  Widget _docCard(String label, String docType, IconData icon) {
    final isConfirmed = _confirmedDocs.contains(docType);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConfirmed ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(icon, color: isConfirmed ? Colors.green : Colors.indigo),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ]),
            ElevatedButton.icon(
              onPressed: () => _pickAndExtract(docType: docType),
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(isConfirmed ? "Confirmed" : "Scan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConfirmed ? Colors.green : Colors.indigo,
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
      case "ID Card Front":
      case "ID Card Back":
        return [
          _kv("NIN", res.nin),
          _kv("Card Number", res.cardNumber),
          _kv("Family Name", res.familyName),
          _kv("Given Name", res.givenName),
          _kv("Birthdate", res.birthdate),
          _kv("Expiry Date", res.expiryDate),
          _kv("Rh", res.rhfactor),
        ];
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
