import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../core/history_manager.dart';
import '../models/history_item.dart';

class UnlockPdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const UnlockPdfScreen({super.key, required this.historyManager});

  @override
  State<UnlockPdfScreen> createState() => _UnlockPdfScreenState();
}

class _UnlockPdfScreenState extends State<UnlockPdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? file;
  bool isLoading = false;
  bool obscurePassword = true;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController outputController = TextEditingController(
    text: "unlocked_pdf",
  );

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    // Copy to safe temp directory
    final tempDir = Directory.systemTemp;
    final safePdfPath =
        '${tempDir.path}/safe_unlock_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(result.files.single.path!).copy(safePdfPath);

    setState(() {
      file = safePdfPath;
      outputController.text =
          "${result.files.single.name.replaceAll('.pdf', '')}-unlocked";
      isLoading = false;
    });
  }

  Future<void> savePdf() async {
    if (file == null || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a file and enter the password"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('unlockPdf', {
        'inputPath': file,
        'password': passwordController.text,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Unlock PDF",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Removed password encryption",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "PDF unlocked successfully")),
      );

      passwordController.clear();
    } catch (e) {
      // Clean up the error message if the user types the wrong password
      String errorMessage = e.toString();
      if (errorMessage.contains("InvalidPasswordException") ||
          errorMessage.contains("password")) {
        errorMessage = "Incorrect password. Could not unlock the PDF.";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
      appBar: AppBar(title: const Text("Unlock PDF")),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Decrypting document..."),
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
                            child: Text("Select Locked PDF File"),
                          ),
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
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.lock_open,
                                        color: Colors.green,
                                        size: 40,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        "Enter the password to permanently unlock this PDF. The resulting file will no longer require a password to open.",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                TextField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: "Current Password",
                                    prefixIcon: const Icon(Icons.key),
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
                  icon: const Icon(Icons.no_encryption),
                  label: const Text("UNLOCK PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
