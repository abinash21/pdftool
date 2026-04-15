import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../core/history_manager.dart';
import '../models/history_item.dart';

class ImageToPdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const ImageToPdfScreen({super.key, required this.historyManager});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  List<String> imagePaths = [];
  bool isLoading = false;

  final TextEditingController outputController = TextEditingController(
    text: "images_to_pdf",
  );

  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result == null) return;

    setState(() => isLoading = true);

    final tempDir = Directory.systemTemp;
    List<String> newPaths = [];

    for (var file in result.files) {
      if (file.path != null) {
        final safeImgPath =
            '${tempDir.path}/safe_img_${DateTime.now().microsecondsSinceEpoch}_${file.name}';
        await File(file.path!).copy(safeImgPath);
        newPaths.add(safeImgPath);
      }
    }

    setState(() {
      imagePaths.addAll(newPaths);
      isLoading = false;
    });
  }

  Future<void> savePdf() async {
    if (imagePaths.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('imageToPdf', {
        'imagePaths': imagePaths,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Image to PDF",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Combined ${imagePaths.length} images into PDF",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "PDF created successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void removeImage(int index) {
    setState(() {
      imagePaths.removeAt(index);
    });
  }

  void clearAll() {
    setState(() {
      imagePaths.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Image to PDF"),
        actions: [
          if (imagePaths.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: clearAll,
              tooltip: "Clear All",
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Building PDF..."),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (imagePaths.isEmpty)
                    Expanded(
                      child: GestureDetector(
                        onTap: pickImages,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text("Select Images"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (imagePaths.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.drag_indicator, color: Colors.purple),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Long press and drag images to reorder them.",
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: imagePaths.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = imagePaths.removeAt(oldIndex);
                            imagePaths.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final path = imagePaths[index];
                          return Card(
                            key: ValueKey(path),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Image.file(
                                File(path),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              title: Text("Image ${index + 1}"),
                              subtitle: Text(
                                path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => removeImage(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: pickImages,
                      icon: const Icon(Icons.add),
                      label: const Text("ADD MORE IMAGES"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: outputController,
                      decoration: const InputDecoration(
                        labelText: "Output filename",
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: imagePaths.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: savePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("CONVERT TO PDF"),
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
