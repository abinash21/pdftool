import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdftool/models/history_item.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../core/history_manager.dart';

class PageNumbersScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const PageNumbersScreen({super.key, required this.historyManager});

  @override
  State<PageNumbersScreen> createState() => _PageNumbersScreenState();
}

class _PageNumbersScreenState extends State<PageNumbersScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? pdfPath;
  ImageProvider? previewThumbnail;
  bool isLoading = false;

  final TextEditingController formatController = TextEditingController(
    text: "Page {n} of {total}",
  );

  final TextEditingController outputController = TextEditingController(
    text: "numbered_pdf",
  );

  String selectedPosition = "BOTTOM RIGHT";

  final List<String> positions = [
    "TOP LEFT",
    "TOP CENTER",
    "TOP RIGHT",
    "BOTTOM LEFT",
    "BOTTOM CENTER",
    "BOTTOM RIGHT",
  ];

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    pdfPath = result.files.single.path!;
    outputController.text =
        "${result.files.single.name.replaceAll('.pdf', '')}-numbered";

    final document = await pdfx.PdfDocument.openFile(pdfPath!);
    final page = await document.getPage(1);
    final pageImage = await page.render(width: page.width, height: page.height);

    setState(() {
      previewThumbnail = MemoryImage(pageImage!.bytes);
      isLoading = false;
    });

    await page.close();
    await document.close();
  }

  Future<void> savePdf() async {
    if (pdfPath == null) return;

    try {
      final result = await _channel.invokeMethod('addPageNumbers', {
        'inputPath': pdfPath,
        'format': formatController.text,
        'position': selectedPosition.replaceAll(" ", "_"),
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Add Page Numbers",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Added to ${selectedPosition.toLowerCase()}",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "Page numbers added successfully")),
      );
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
              Text("Rendering PDF preview..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Page Numbers")),
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
                                previewThumbnail = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        children: [
                          if (previewThumbnail != null)
                            Container(
                              height: 200,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image(
                                image: previewThumbnail!,
                                fit: BoxFit.contain,
                              ),
                            ),

                          TextField(
                            controller: formatController,
                            decoration: const InputDecoration(
                              labelText: "Label Format",
                              helperText:
                                  "Use {n} for page number and {total} for total pages.",
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            "POSITION",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: positions.length,
                            itemBuilder: (context, index) {
                              final isSelected =
                                  selectedPosition == positions[index];

                              return GestureDetector(
                                onTap: () => setState(
                                  () => selectedPosition = positions[index],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outlineVariant,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    positions[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

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

      bottomNavigationBar: pdfPath != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: savePdf,
                  child: const Text("ADD PAGE NUMBERS"),
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    formatController.dispose();
    outputController.dispose();
    super.dispose();
  }
}
