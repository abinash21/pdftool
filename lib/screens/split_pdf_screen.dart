import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../core/history_manager.dart';
import '../models/history_item.dart';

class SplitPdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const SplitPdfScreen({super.key, required this.historyManager});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? file;

  bool isLoading = false;

  final startController = TextEditingController();
  final endController = TextEditingController();
  final outputController = TextEditingController(text: "pdftool-split");

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        file = result.files.single.path!;
      });
    }
  }

  /// ✅ Validation
  bool get _canSplit {
    if (file == null) return false;

    final start = int.tryParse(startController.text);
    final end = int.tryParse(endController.text);

    if (start == null || end == null) return false;
    if (start < 1) return false;
    if (end < start) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Split PDF")),
      body: Padding(
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
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: const Center(child: Text("Select PDF File")),
                  ),
                ),
              ),

            if (file != null)
              Expanded(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(file!.split('/').last),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            file = null;
                          });
                        },
                      ),
                    ),

                    TextField(
                      controller: outputController,
                      decoration: const InputDecoration(
                        labelText: "Output filename",
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Start Page",
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: TextField(
                            controller: endController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "End Page",
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                  ],
                ),
              ),
          ],
        ),
      ),

      /// ✅ Bottom button
      bottomNavigationBar: file != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _canSplit
                      ? () async {
                          final result = await _channel.invokeMethod('split', {
                            'inputPath': file,
                            'startPage': int.parse(startController.text),
                            'endPage': int.parse(endController.text),
                            'outputName': outputController.text,
                          });

                          widget.historyManager.addHistory(
                            HistoryItem(
                              action: "Split PDF",
                              outputPath: result ?? "",
                              dateTime: DateTime.now(),
                              details:
                                  "Pages ${startController.text}-${endController.text}",
                            ),
                          );

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result ?? "Split complete")),
                          );
                        }
                      : null,
                  child: const Text("SPLIT PDF"),
                ),
              ),
            )
          : null,
    );
  }
}
