import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../core/history_manager.dart';
import '../models/history_item.dart';

class MetadataPdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const MetadataPdfScreen({super.key, required this.historyManager});

  @override
  State<MetadataPdfScreen> createState() => _MetadataPdfScreenState();
}

class _MetadataPdfScreenState extends State<MetadataPdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? file;
  bool isLoading = false;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController keywordsController = TextEditingController();
  final TextEditingController creatorController = TextEditingController();
  final TextEditingController outputController = TextEditingController(
    text: "metadata_updated",
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
        '${tempDir.path}/safe_meta_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(result.files.single.path!).copy(safePdfPath);

    file = safePdfPath;
    outputController.text =
        "${result.files.single.name.replaceAll('.pdf', '')}-meta";

    try {
      final Map<Object?, Object?>? meta = await _channel.invokeMethod(
        'readMetadata',
        {'inputPath': file},
      );

      if (meta != null) {
        titleController.text = (meta['title'] as String?) ?? "";
        authorController.text = (meta['author'] as String?) ?? "";
        subjectController.text = (meta['subject'] as String?) ?? "";
        keywordsController.text = (meta['keywords'] as String?) ?? "";
        creatorController.text = (meta['creator'] as String?) ?? "";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not read existing metadata: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> savePdf() async {
    if (file == null) return;

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('writeMetadata', {
        'inputPath': file,
        'title': titleController.text,
        'author': authorController.text,
        'subject': subjectController.text,
        'keywords': keywordsController.text,
        'creator': creatorController.text,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Edit Metadata",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Updated document properties",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "Metadata updated successfully")),
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
      titleController.clear();
      authorController.clear();
      subjectController.clear();
      keywordsController.clear();
      creatorController.clear();
    });
  }

  Widget _buildMetaField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Metadata")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                            margin: const EdgeInsets.only(bottom: 16),
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
                                  "DOCUMENT PROPERTIES",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _buildMetaField(
                                  "Title",
                                  Icons.title,
                                  titleController,
                                ),
                                _buildMetaField(
                                  "Author",
                                  Icons.person,
                                  authorController,
                                ),
                                _buildMetaField(
                                  "Subject",
                                  Icons.subject,
                                  subjectController,
                                ),
                                _buildMetaField(
                                  "Keywords",
                                  Icons.vpn_key,
                                  keywordsController,
                                ),
                                _buildMetaField(
                                  "Creator/Application",
                                  Icons.computer,
                                  creatorController,
                                ),

                                const Divider(height: 32),

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
      bottomNavigationBar: file != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: savePdf,
                  icon: const Icon(Icons.save),
                  label: const Text("SAVE METADATA"),
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    subjectController.dispose();
    keywordsController.dispose();
    creatorController.dispose();
    outputController.dispose();
    super.dispose();
  }
}
