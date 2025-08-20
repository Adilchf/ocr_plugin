// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:ocr_plugin/ocr_plugin.dart'; // your plugin

// class PassportPage extends StatefulWidget {
//   const PassportPage({super.key});

//   @override
//   State<PassportPage> createState() => _PassportPageState();
// }

// class _PassportPageState extends State<PassportPage> {
//   OcrResult? _result;
//   bool _loading = false;

//   Future<void> _pickAndExtract() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile == null) return;

//     setState(() => _loading = true);

//     try {
//       final file = File(pickedFile.path);
//       // 👇 enable face detection + cropping so facePath gets filled
//       final result = await OcrPlugin.extractData(file, detectAndCropFace: true);

//       if (!mounted) return;
//       setState(() {
//         _result = result;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Extraction failed: $e')));
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasResult = _result != null && !_loading;
//     final hasFace =
//         hasResult && _result!.facePath != null && _result!.facePath!.isNotEmpty;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Card OCR")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ElevatedButton.icon(
//               icon: const Icon(Icons.image),
//               label: const Text("Pick Card"),
//               onPressed: _pickAndExtract,
//             ),
//             const SizedBox(height: 20),

//             if (_loading) const Center(child: CircularProgressIndicator()),

//             if (hasResult)
//               Expanded(
//                 child: ListView(
//                   children: [
//                     // --- Extracted data ---
//                     _kv('NIN', _result!.nin),
//                     _kv('Card Number', _result!.cardNumberPassport),
//                     _kv('Family Name', _result!.familyNamePassport),
//                     _kv('Given Name', _result!.givenName),
//                     _kv('Birthdate', _result!.birthdate),
//                     _kv('Expiry Date', _result!.expiryDate),
//                     _kv('Rh', _result!.rhfactor),

//                     if (_result!.faceOk != null)
//                       _kv('Face OK', _result!.faceOk! ? 'Yes' : 'No'),
//                     if (_result!.faceError != null &&
//                         _result!.faceError!.isNotEmpty)
//                       _kv('Face Error', _result!.faceError),

//                     const SizedBox(height: 16),
//                     const Divider(height: 1),
//                     const SizedBox(height: 16),

//                     // --- Cropped face photo printed BELOW the data ---
//                     Text(
//                       'Extracted Photo',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 12),

//                     AspectRatio(
//                       aspectRatio: 1, // square box
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade200,
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         clipBehavior: Clip.antiAlias,
//                         child: hasFace
//                             ? Image.file(
//                                 File(_result!.facePath!),
//                                 height: 30,
//                                 width: 30,
//                                 errorBuilder: (ctx, err, stack) =>
//                                     const _PhotoPlaceholder(),
//                               )
//                             : const _PhotoPlaceholder(),
//                       ),
//                     ),

//                     if (hasFace) ...[
//                       const SizedBox(height: 8),
//                       Text(
//                         _result!.facePath!,
//                         style: Theme.of(context).textTheme.bodySmall,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _kv(String label, String? value) {
//     if (value == null || value.isEmpty) return const SizedBox.shrink();
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 150,
//             child: Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }
// }

// class _PhotoPlaceholder extends StatelessWidget {
//   const _PhotoPlaceholder();

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Icon(Icons.person_off, size: 40, color: Colors.black38),
//     );
//   }
// }
