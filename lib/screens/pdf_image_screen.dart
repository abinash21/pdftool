import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../core/history_manager.dart';
import '../models/history_item.dart';

class PdfToImageScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const PdfToImageScreen({super.key, required this.historyManager});

  @override
  State<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends State<PdfToImageScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? file;
  bool isLoading = false;
  String selectedFormat = "JPG";

  final TextEditingController outputController = TextEditingController(
    text: "pdf_images",
  );

  final TextEditingController pagesController = TextEditingController();

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    final tempDir = Directory.systemTemp;
    final safePdfPath =
        '${tempDir.path}/safe_img_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(result.files.single.path!).copy(safePdfPath);

    setState(() {
      file = safePdfPath;
      outputController.text =
          "${result.files.single.name.replaceAll('.pdf', '')}-images";
      pagesController.text = ""; // Reset on new file
      isLoading = false;
    });
  }

  Future<void> saveZip() async {
    if (file == null) return;

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('pdfToImage', {
        'inputPath': file,
        'format': selectedFormat,
        'pages': pagesController.text.trim().isEmpty
            ? "all"
            : pagesController.text.trim(),
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "PDF to Image",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Converted to $selectedFormat ZIP archive",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "Images extracted successfully")),
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
      appBar: AppBar(title: const Text("PDF to Image")),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Rendering pages to images..."),
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
                                const Text(
                                  "SELECT IMAGE FORMAT",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text("JPG"),
                                        subtitle: const Text(
                                          "Smaller file size",
                                        ),
                                        value: "JPG",
                                        groupValue: selectedFormat,
                                        onChanged: (value) => setState(
                                          () => selectedFormat = value!,
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text("PNG"),
                                        subtitle: const Text("High quality"),
                                        value: "PNG",
                                        groupValue: selectedFormat,
                                        onChanged: (value) => setState(
                                          () => selectedFormat = value!,
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // NEW: Pages Input Field
                                TextField(
                                  controller: pagesController,
                                  decoration: const InputDecoration(
                                    labelText: "Pages (e.g. 1, 3, 5-8)",
                                    hintText:
                                        "Leave blank to convert all pages",
                                    prefixIcon: Icon(
                                      Icons.format_list_numbered,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                TextField(
                                  controller: outputController,
                                  decoration: const InputDecoration(
                                    labelText: "Output filename (.zip)",
                                    prefixIcon: Icon(Icons.save),
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
                  onPressed: saveZip,
                  icon: const Icon(Icons.image),
                  label: const Text("CONVERT TO IMAGES"),
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    outputController.dispose();
    pagesController.dispose();
    super.dispose();
  }
}
