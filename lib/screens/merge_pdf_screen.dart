import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../core/history_manager.dart';
import '../models/history_item.dart';

class MergePdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const MergePdfScreen({super.key, required this.historyManager});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  List<String> files = [];

  final TextEditingController outputController = TextEditingController(
    text: "pdftool-merged",
  );

  Future<void> pickFiles({bool append = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      final selected = result.paths.whereType<String>().toList();

      setState(() {
        if (append) {
          files.addAll(selected);
        } else {
          files = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Merge PDF")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (files.isEmpty)
              Expanded(
                child: GestureDetector(
                  onTap: () => pickFiles(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: const Center(child: Text("Select PDF Files")),
                  ),
                ),
              ),

            if (files.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    ...files.map((file) {
                      final name = file.split('/').last;

                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(name),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              files.remove(file);
                            });
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => pickFiles(append: true),
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: const Text("+ ADD MORE FILES"),
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

      bottomNavigationBar: files.length >= 2
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await _channel.invokeMethod('merge', {
                      'files': files,
                      'outputName': outputController.text,
                    });

                    widget.historyManager.addHistory(
                      HistoryItem(
                        action: "Merge PDF",
                        outputPath: result ?? "",
                        dateTime: DateTime.now(),
                        details: "${files.length} files merged",
                      ),
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result ?? "Merge complete")),
                    );
                  },
                  child: const Text("MERGE PDF"),
                ),
              ),
            )
          : null,
    );
  }
}
