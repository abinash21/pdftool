import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdftool/models/history_item.dart';

import '../core/history_manager.dart';

class CompressPdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const CompressPdfScreen({super.key, required this.historyManager});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? pdfPath;
  int originalSizeBytes = 0;
  bool isLoading = false;

  String selectedMode = "STANDARD";

  final TextEditingController outputController = TextEditingController(
    text: "compressed_pdf",
  );

  final List<Map<String, dynamic>> compressionOptions = [
    {
      "id": "HIGH_QUALITY",
      "title": "HIGH QUALITY",
      "subtitle": "Expected Reduction: 10-30%",
      "minFactor": 0.70,
      "maxFactor": 0.90,
    },
    {
      "id": "STANDARD",
      "title": "STANDARD",
      "subtitle": "Expected Reduction: 40-60%",
      "minFactor": 0.40,
      "maxFactor": 0.60,
    },
    {
      "id": "SMALLEST",
      "title": "SMALLEST",
      "subtitle": "Expected Reduction: 70-90%",
      "minFactor": 0.10,
      "maxFactor": 0.30,
    },
  ];

  String formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  String getExpectedSizeString(Map<String, dynamic> option) {
    if (originalSizeBytes == 0) return "Unknown";
    int minSize = (originalSizeBytes * option['minFactor']).toInt();
    int maxSize = (originalSizeBytes * option['maxFactor']).toInt();
    return "${formatBytes(minSize)} - ${formatBytes(maxSize)}";
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    // --- FIX: Copy PDF to a safe system temp folder ---
    final tempDir = Directory.systemTemp;
    final safePdfPath =
        '${tempDir.path}/safe_compress_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = await File(result.files.single.path!).copy(safePdfPath);
    // --------------------------------------------------

    final size = await file.length();

    setState(() {
      pdfPath = file.path;
      originalSizeBytes = size;
      outputController.text =
          "${result.files.single.name.replaceAll('.pdf', '')}-compressed";
      isLoading = false;
    });
  }

  Future<void> savePdf() async {
    if (pdfPath == null) return;

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('compress', {
        'inputPath': pdfPath,
        'mode': selectedMode,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Compress PDF",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Mode: $selectedMode",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "PDF Compressed Successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void closeFile() {
    setState(() {
      pdfPath = null;
      originalSizeBytes = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Compress PDF")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (pdfPath == null)
                    Expanded(
                      child: GestureDetector(
                        onTap: pickFile,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: const Center(child: Text("Select PDF File")),
                        ),
                      ),
                    ),
                  if (pdfPath != null)
                    Expanded(
                      child: Column(
                        children: [
                          // FILE CARD (Now includes Original Size)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf, size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pdfPath!.split('/').last,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Original Size: ${formatBytes(originalSizeBytes)}",
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: closeFile,
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: ListView(
                              children: [
                                const Text(
                                  "SELECT COMPRESSION LEVEL",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // COMPRESSION OPTIONS
                                ...compressionOptions.map((option) {
                                  bool isSelected =
                                      selectedMode == option['id'];

                                  return GestureDetector(
                                    onTap: () => setState(
                                      () => selectedMode = option['id'],
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colorScheme.primary.withOpacity(
                                                0.1,
                                              )
                                            : colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.outlineVariant,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<String>(
                                            value: option['id'],
                                            groupValue: selectedMode,
                                            onChanged: (val) => setState(
                                              () => selectedMode = val!,
                                            ),
                                            activeColor: colorScheme.primary,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  option['title'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  option['subtitle'],
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                "Expected",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              Text(
                                                getExpectedSizeString(option),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                                const SizedBox(height: 24),

                                TextField(
                                  controller: outputController,
                                  decoration: const InputDecoration(
                                    labelText: "Output filename",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: pdfPath != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: savePdf,
                  icon: const Icon(Icons.compress),
                  label: const Text("COMPRESS PDF"),
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    outputController.dispose();
    super.dispose();
  }
}
