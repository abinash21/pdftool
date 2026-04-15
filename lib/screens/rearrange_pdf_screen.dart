import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdftool/models/history_item.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../core/history_manager.dart';

class RearrangePdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const RearrangePdfScreen({super.key, required this.historyManager});

  @override
  State<RearrangePdfScreen> createState() => _RearrangePdfScreenState();
}

class _RearrangePdfScreenState extends State<RearrangePdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? pdfPath;
  pdfx.PdfDocument? previewDocument;

  List<ImageProvider?> thumbnails = [];
  List<int> pageOrder = []; // Tracks the 1-based page numbers

  bool isLoading = false;

  final TextEditingController outputController = TextEditingController(
    text: "rearranged_pdf",
  );

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    pdfPath = result.files.single.path!;
    previewDocument = await pdfx.PdfDocument.openFile(pdfPath!);

    final pageCount = previewDocument!.pagesCount;

    thumbnails.clear();
    pageOrder.clear();

    for (int i = 1; i <= pageCount; i++) {
      final page = await previewDocument!.getPage(i);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
      );

      thumbnails.add(MemoryImage(pageImage!.bytes));
      pageOrder.add(i); // Initialize with default 1, 2, 3... order

      await page.close();
      if (!mounted) return;
    }

    setState(() => isLoading = false);
  }

  Future<void> savePdf() async {
    if (pdfPath == null) return;

    try {
      final result = await _channel.invokeMethod('rearrange', {
        'inputPath': pdfPath,
        'pageOrder': pageOrder,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Rearrange PDF",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Reordered ${pageOrder.length} pages",
        ),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result ?? "Rearrange complete")));
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
      appBar: AppBar(title: const Text("Rearrange PDF")),
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
                    TextField(
                      controller: outputController,
                      decoration: const InputDecoration(
                        labelText: "Output filename",
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "LONG PRESS AND DRAG TO REORDER",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ReorderableGridView.builder(
                        itemCount: thumbnails.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            // Synchronize our data arrays when a tile is dropped
                            final thumb = thumbnails.removeAt(oldIndex);
                            final pageNum = pageOrder.removeAt(oldIndex);
                            thumbnails.insert(newIndex, thumb);
                            pageOrder.insert(newIndex, pageNum);
                          });
                        },
                        itemBuilder: (context, index) {
                          final originalPageNum = pageOrder[index];

                          return Container(
                            // ReorderableGridView REQUIRES a unique key for every item
                            key: ValueKey("page_$originalPageNum"),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Image(
                                    image: thumbnails[index]!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.black54,
                                    child: Text(
                                      "PAGE $originalPageNum",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                  child: const Text("SAVE REARRANGED PDF"),
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
