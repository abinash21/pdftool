import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../core/history_manager.dart';
import '../models/history_item.dart';

class PdfToTextScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const PdfToTextScreen({super.key, required this.historyManager});

  @override
  State<PdfToTextScreen> createState() => _PdfToTextScreenState();
}

class _PdfToTextScreenState extends State<PdfToTextScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? file;
  bool isLoading = false;

  final TextEditingController outputController = TextEditingController(
    text: "extracted_text",
  );

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    final tempDir = Directory.systemTemp;
    final safePdfPath =
        '${tempDir.path}/safe_text_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(result.files.single.path!).copy(safePdfPath);

    setState(() {
      file = safePdfPath;
      outputController.text =
          "${result.files.single.name.replaceAll('.pdf', '')}-text";
      isLoading = false;
    });
  }

  Future<void> saveTextFile() async {
    if (file == null) return;

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('pdfToText', {
        'inputPath': file,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "PDF to Text",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Extracted text to .txt file",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "Text extracted successfully")),
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
      appBar: AppBar(title: const Text("PDF to Text")),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Extracting text from document..."),
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
                          child: const Center(child: Text("Select PDF File")),
                        ),
                      ),
                    ),
                  if (file != null)
                    Expanded(
                      child: Column(
                        children: [
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
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.teal.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.text_snippet,
                                        color: Colors.teal,
                                        size: 40,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        "This tool will extract all readable text from the PDF and save it as a standard .txt file. Note: Text inside flattened images or scans cannot be extracted.",
                                        style: TextStyle(
                                          color: Colors.teal,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                TextField(
                                  controller: outputController,
                                  decoration: const InputDecoration(
                                    labelText:
                                        "Output filename (will be a .txt file)",
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
      bottomNavigationBar: file != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: saveTextFile,
                  icon: const Icon(Icons.text_fields),
                  label: const Text("EXTRACT TEXT"),
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
