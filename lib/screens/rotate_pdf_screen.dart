import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdftool/models/history_item.dart';
import 'dart:math';

import 'package:pdfx/pdfx.dart' as pdfx;

import '../core/history_manager.dart';

class RotatePdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const RotatePdfScreen({super.key, required this.historyManager});

  @override
  State<RotatePdfScreen> createState() => _RotatePdfScreenState();
}

class _RotatePdfScreenState extends State<RotatePdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? pdfPath;

  pdfx.PdfDocument? previewDocument;

  List<ImageProvider?> thumbnails = [];

  Map<int, int> rotations = {};

  int pageCount = 0;

  bool isLoading = false;

  final TextEditingController outputController = TextEditingController(
    text: "rotated_pdf",
  );

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() {
      isLoading = true;
    });

    pdfPath = result.files.single.path!;

    previewDocument = await pdfx.PdfDocument.openFile(pdfPath!);

    pageCount = previewDocument!.pagesCount;

    thumbnails.clear();
    rotations.clear();

    for (int i = 1; i <= pageCount; i++) {
      final page = await previewDocument!.getPage(i);

      final pageImage = await page.render(
        width: page.width,
        height: page.height,
      );

      thumbnails.add(MemoryImage(pageImage!.bytes));

      await page.close();

      if (!mounted) return;
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  void rotatePage(int index) {
    setState(() {
      int current = rotations[index] ?? 0;

      current += 90;

      if (current >= 360) current = 0;

      rotations[index] = current;
    });
  }

  void rotateAll() {
    setState(() {
      for (int i = 0; i < pageCount; i++) {
        int current = rotations[i] ?? 0;

        current += 90;

        if (current >= 360) current = 0;

        rotations[i] = current;
      }
    });
  }

  void resetRotation() {
    setState(() {
      rotations.clear();
    });
  }

  Future<void> savePdf() async {
    if (pdfPath == null) return;

    try {
      final result = await _channel.invokeMethod('rotate', {
        'inputPath': pdfPath,
        'rotations': rotations,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Rotate PDF",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Pages rotated",
        ),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result ?? "Rotate complete")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Rendering PDF pages..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Rotate PDF")),

      body: Padding(
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
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: const Center(child: Text("Select PDF File")),
                  ),
                ),
              ),

            if (pdfPath != null)
              Expanded(
                child: Column(
                  children: [
                    /// FILE CARD
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              pdfPath!.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                pdfPath = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    /// OUTPUT NAME
                    TextField(
                      controller: outputController,
                      decoration: const InputDecoration(
                        labelText: "Output filename",
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ACTIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("PAGE PREVIEW"),

                        Row(
                          children: [
                            TextButton(
                              onPressed: rotateAll,
                              child: const Text("ALL"),
                            ),

                            TextButton(
                              onPressed: resetRotation,
                              child: const Text("RESET"),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// PAGE GRID
                    Expanded(
                      child: GridView.builder(
                        itemCount: pageCount,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),

                        itemBuilder: (context, index) {
                          final rotation = rotations[index] ?? 0;

                          return GestureDetector(
                            onTap: () => rotatePage(index),

                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),

                              child: Stack(
                                children: [
                                  Center(
                                    child: Transform.rotate(
                                      angle: rotation * pi / 180,
                                      child: Image(
                                        image: thumbnails[index]!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      color: Colors.black54,
                                      child: Text(
                                        "PAGE ${index + 1}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                child: ElevatedButton(
                  onPressed: savePdf,
                  child: const Text("SAVE ROTATED PDF"),
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
