import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../core/history_manager.dart';
import '../models/history_item.dart';

class ProtectPdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const ProtectPdfScreen({super.key, required this.historyManager});

  @override
  State<ProtectPdfScreen> createState() => _ProtectPdfScreenState();
}

class _ProtectPdfScreenState extends State<ProtectPdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? file;
  bool isLoading = false;
  bool obscurePassword = true;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController outputController = TextEditingController(
    text: "protected_pdf",
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
        '${tempDir.path}/safe_protect_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(result.files.single.path!).copy(safePdfPath);

    setState(() {
      file = safePdfPath;
      outputController.text =
          "${result.files.single.name.replaceAll('.pdf', '')}-protected";
      isLoading = false;
    });
  }

  Future<void> savePdf() async {
    if (file == null || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a file and enter a password"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('protectPdf', {
        'inputPath': file,
        'password': passwordController.text,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Protect PDF",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Added password encryption",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "PDF protected successfully")),
      );

      // Clear password field after saving for security
      passwordController.clear();
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
      passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Protect PDF")),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Encrypting document..."),
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
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.redAccent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.security,
                                        color: Colors.redAccent,
                                        size: 40,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        "Encrypt this PDF. Anyone opening this file will be required to enter the password below.",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                /// PASSWORD INPUT
                                TextField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: "Set Password",
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () => setState(
                                        () =>
                                            obscurePassword = !obscurePassword,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

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
                  icon: const Icon(Icons.lock_outline),
                  label: const Text("PROTECT PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    outputController.dispose();
    super.dispose();
  }
}
