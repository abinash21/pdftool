import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../core/history_manager.dart';
import '../models/history_item.dart';

class RepairPdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const RepairPdfScreen({super.key, required this.historyManager});

  @override
  State<RepairPdfScreen> createState() => _RepairPdfScreenState();
}

class _RepairPdfScreenState extends State<RepairPdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? file;
  bool isLoading = false;

  final TextEditingController outputController = TextEditingController(
    text: "repaired_pdf",
  );

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    // Copy to safe temp directory to prevent file_picker auto-deletion
    final tempDir = Directory.systemTemp;
    final safePdfPath =
        '${tempDir.path}/safe_repair_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(result.files.single.path!).copy(safePdfPath);

    setState(() {
      file = safePdfPath;
      outputController.text =
          "${result.files.single.name.replaceAll('.pdf', '')}-repaired";
      isLoading = false;
    });
  }

  Future<void> savePdf() async {
    if (file == null) return;

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('repairPdf', {
        'inputPath': file,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Repair PDF",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Rebuilt corrupted PDF structure",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "PDF repaired successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void closeFile() {
    setState(() {
      file = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Repair PDF")),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Rebuilding document structure..."),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (file == null)
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
                          child: const Center(
                            child: Text("Select Corrupted PDF File"),
                          ),
                        ),
                      ),
                    ),
                  if (file != null)
                    Expanded(
                      child: Column(
                        children: [
                          /// FILE CARD
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
                                const Icon(Icons.picture_as_pdf),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    file!.split('/').last,
                                    overflow: TextOverflow.ellipsis,
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
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.build_circle,
                                        color: Colors.blueAccent,
                                        size: 40,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        "This tool attempts to recover content from corrupted or damaged PDF files by rebuilding the cross-reference tables and fixing broken streams.",
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                /// OUTPUT FILENAME
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

      /// BOTTOM BUTTON
      bottomNavigationBar: file != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: savePdf,
                  icon: const Icon(Icons.healing),
                  label: const Text("REPAIR PDF"),
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
