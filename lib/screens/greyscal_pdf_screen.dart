import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../core/history_manager.dart';
import '../models/history_item.dart';

class GreyscalePdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const GreyscalePdfScreen({super.key, required this.historyManager});

  @override
  State<GreyscalePdfScreen> createState() => _GreyscalePdfScreenState();
}

class _GreyscalePdfScreenState extends State<GreyscalePdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? file;
  pdfx.PdfDocument? previewDocument;
  pdfx.PdfPageImage? currentPageImage;
  bool isLoading = false;

  final TextEditingController outputController = TextEditingController(
    text: "greyscale_pdf",
  );

  static const ColorFilter greyscaleFilter = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    final tempDir = Directory.systemTemp;
    final safePdfPath =
        '${tempDir.path}/safe_grey_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(result.files.single.path!).copy(safePdfPath);

    file = safePdfPath;
    outputController.text =
        "${result.files.single.name.replaceAll('.pdf', '')}-greyscale";

    try {
      previewDocument = await pdfx.PdfDocument.openFile(file!);
      final page = await previewDocument!.getPage(1);
      currentPageImage = await page.render(
        width: page.width,
        height: page.height,
      );
      await page.close();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error rendering preview: $e")));
      closeFile();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> savePdf() async {
    if (file == null) return;

    setState(() => isLoading = true);

    try {
      final result = await _channel.invokeMethod('convertToGreyscale', {
        'inputPath': file,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Convert to Greyscale",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Converted colors to B&W",
        ),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result ?? "Conversion complete")));
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
      previewDocument?.close();
      previewDocument = null;
      currentPageImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Convert to Greyscale")),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Processing..."),
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
                            margin: const EdgeInsets.only(bottom: 20),
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
                                /// LIVE GREYSCALE PREVIEW
                                if (currentPageImage != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: AspectRatio(
                                      aspectRatio:
                                          currentPageImage!.width! /
                                          currentPageImage!.height!,
                                      child: ColorFiltered(
                                        colorFilter: greyscaleFilter,
                                        child: Image.memory(
                                          currentPageImage!.bytes,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                const Text(
                                  "This tool will convert all text, images, and graphics inside the PDF into black, white, and grey.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

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

      bottomNavigationBar: file != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: savePdf,
                  icon: const Icon(Icons.format_color_reset),
                  label: const Text("CONVERT TO GREYSCALE"),
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    outputController.dispose();
    previewDocument?.close();
    super.dispose();
  }
}
