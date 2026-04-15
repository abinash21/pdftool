import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdftool/models/history_item.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../core/history_manager.dart';

// Now tracks the specific image path for every single placement
class SignatureData {
  double dx;
  double dy;
  double width;
  int pageNum;
  String imagePath; // <-- NEW: Remembers its own image

  SignatureData({
    required this.dx,
    required this.dy,
    required this.width,
    required this.pageNum,
    required this.imagePath,
  });

  Map<String, dynamic> toMap(double boxWidth, double boxHeight) {
    return {
      'page': pageNum,
      'xPercent': dx / boxWidth,
      'yPercent': dy / boxHeight,
      'widthPercent': width / boxWidth,
      'imagePath': imagePath, // Send this to Native Java
    };
  }
}

class SignaturePdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const SignaturePdfScreen({super.key, required this.historyManager});

  @override
  State<SignaturePdfScreen> createState() => _SignaturePdfScreenState();
}

class _SignaturePdfScreenState extends State<SignaturePdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? pdfPath;
  pdfx.PdfDocument? previewDocument;
  pdfx.PdfPageImage? currentPageImage;
  int totalPages = 0;
  int previewPageNum = 1;

  String? currentSignaturePath; // The currently loaded signature ready to stamp
  bool isLoading = false;

  List<SignatureData> placements = [];
  SignatureData? selectedSignature;

  final TextEditingController outputController = TextEditingController(
    text: "signed_pdf",
  );

  double currentBoxWidth = 300.0;
  double currentBoxHeight = 400.0;

  Future<void> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    final tempDir = Directory.systemTemp;
    final safePdfPath =
        '${tempDir.path}/safe_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(result.files.single.path!).copy(safePdfPath);

    pdfPath = safePdfPath;
    outputController.text =
        "${result.files.single.name.replaceAll('.pdf', '')}-signed";

    try {
      previewDocument = await pdfx.PdfDocument.openFile(pdfPath!);
      totalPages = previewDocument!.pagesCount;
      await loadPreviewPage(1);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      closeFile();
    }
  }

  Future<void> loadPreviewPage(int pageNum) async {
    setState(() => isLoading = true);
    try {
      final page = await previewDocument!.getPage(pageNum);
      currentPageImage = await page.render(
        width: page.width,
        height: page.height,
      );
      previewPageNum = pageNum;
      selectedSignature = null;
      await page.close();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickSignatureImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final tempDir = Directory.systemTemp;
      final safeSigPath =
          '${tempDir.path}/safe_sig_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(result.files.single.path!).copy(safeSigPath);

      setState(() {
        currentSignaturePath = safeSigPath;
      });
    }
  }

  void addSignatureToCurrentPage() {
    if (currentSignaturePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a signature image first.")),
      );
      return;
    }
    setState(() {
      final newSig = SignatureData(
        dx: 50.0,
        dy: 50.0,
        width: 100.0,
        pageNum: previewPageNum,
        imagePath:
            currentSignaturePath!, // Lock in the currently selected image
      );
      placements.add(newSig);
      selectedSignature = newSig;
    });
  }

  void deleteSignature(SignatureData sig) {
    setState(() {
      placements.remove(sig);
      if (selectedSignature == sig) {
        selectedSignature = null;
      }
    });
  }

  void clearCurrentSignature() {
    setState(() {
      currentSignaturePath = null;
    });
  }

  Future<void> savePdf() async {
    if (pdfPath == null || placements.isEmpty) return;

    List<Map<String, dynamic>> nativePlacements = placements
        .map((s) => s.toMap(currentBoxWidth, currentBoxHeight))
        .toList();

    try {
      final result = await _channel.invokeMethod('addSignature', {
        'inputPath': pdfPath,
        'placements':
            nativePlacements, // Native side will extract the image path from this list
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Add Signatures",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Added ${placements.length} signatures",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "Signatures added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void closeFile() {
    setState(() {
      pdfPath = null;
      currentSignaturePath = null;
      previewDocument?.close();
      previewDocument = null;
      currentPageImage = null;
      placements.clear();
      selectedSignature = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    List<SignatureData> currentPagePlacements = placements
        .where((p) => p.pageNum == previewPageNum)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Signatures")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (pdfPath == null)
                    Expanded(
                      child: GestureDetector(
                        onTap: pickPdfFile,
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
                  if (pdfPath != null)
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
                                    pdfPath!.split('/').last,
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
                                if (currentPageImage != null)
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.outlineVariant,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: AspectRatio(
                                      aspectRatio:
                                          currentPageImage!.width! /
                                          currentPageImage!.height!,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          currentBoxWidth =
                                              constraints.maxWidth;
                                          currentBoxHeight =
                                              constraints.maxHeight;

                                          return Stack(
                                            children: [
                                              GestureDetector(
                                                onTap: () => setState(
                                                  () =>
                                                      selectedSignature = null,
                                                ),
                                                child: Image.memory(
                                                  currentPageImage!.bytes,
                                                  fit: BoxFit.contain,
                                                  width: constraints.maxWidth,
                                                ),
                                              ),

                                              // Render Signatures using their OWN saved image paths
                                              ...currentPagePlacements.map((
                                                sig,
                                              ) {
                                                bool isSelected =
                                                    sig == selectedSignature;

                                                return Positioned(
                                                  left: sig.dx,
                                                  top: sig.dy,
                                                  child: GestureDetector(
                                                    onTap: () => setState(
                                                      () => selectedSignature =
                                                          sig,
                                                    ),
                                                    onPanUpdate: (details) {
                                                      setState(() {
                                                        selectedSignature = sig;
                                                        sig.dx =
                                                            (sig.dx +
                                                                    details
                                                                        .delta
                                                                        .dx)
                                                                .clamp(
                                                                  0.0,
                                                                  currentBoxWidth -
                                                                      sig.width,
                                                                );
                                                        sig.dy =
                                                            (sig.dy +
                                                                    details
                                                                        .delta
                                                                        .dy)
                                                                .clamp(
                                                                  0.0,
                                                                  currentBoxHeight -
                                                                      30.0,
                                                                );
                                                      });
                                                    },
                                                    child: Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? Colors
                                                                        .blueAccent
                                                                  : Colors
                                                                        .transparent,
                                                              width: 2,
                                                              style: BorderStyle
                                                                  .solid,
                                                            ),
                                                          ),
                                                          child: Image.file(
                                                            File(
                                                              sig.imagePath,
                                                            ), // <-- Loads its unique image
                                                            width: sig.width,
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          Positioned(
                                                            right: -10,
                                                            top: -10,
                                                            child: GestureDetector(
                                                              onTap: () =>
                                                                  deleteSignature(
                                                                    sig,
                                                                  ),
                                                              child: const CircleAvatar(
                                                                radius: 12,
                                                                backgroundColor:
                                                                    Colors.red,
                                                                child: Icon(
                                                                  Icons.close,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: previewPageNum > 1
                                          ? () => loadPreviewPage(
                                              previewPageNum - 1,
                                            )
                                          : null,
                                    ),
                                    Text(
                                      "Previewing Page $previewPageNum of $totalPages",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: previewPageNum < totalPages
                                          ? () => loadPreviewPage(
                                              previewPageNum + 1,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // UPLOAD / PREVIEW BOX
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: currentSignaturePath == null
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: pickSignatureImage,
                                                icon: const Icon(
                                                  Icons.upload_file,
                                                ),
                                                label: const Text(
                                                  "UPLOAD SIGNATURE",
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colorScheme.surface,
                                                  foregroundColor:
                                                      colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Container(
                                              height: 50,
                                              width: 100,
                                              color: Colors.white,
                                              child: Image.file(
                                                File(currentSignaturePath!),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                              ),
                                              onPressed: clearCurrentSignature,
                                              tooltip:
                                                  "Clear Uploaded Signature",
                                            ),
                                            const Spacer(),
                                            ElevatedButton.icon(
                                              onPressed:
                                                  addSignatureToCurrentPage,
                                              icon: const Icon(Icons.add),
                                              label: const Text("STAMP HERE"),
                                            ),
                                          ],
                                        ),
                                ),

                                // --- DYNAMIC SLIDER FOR SELECTED SIGNATURE ---
                                if (selectedSignature != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blueAccent.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Resize Active Signature",
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${selectedSignature!.width.toInt()}px",
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Slider(
                                          value: selectedSignature!.width,
                                          min: 30.0,
                                          max: currentBoxWidth > 30
                                              ? currentBoxWidth * 0.8
                                              : 200.0,
                                          onChanged: (val) {
                                            setState(() {
                                              selectedSignature!.width = val;
                                              if (selectedSignature!.dx + val >
                                                  currentBoxWidth) {
                                                selectedSignature!.dx =
                                                    currentBoxWidth - val;
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),
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
      bottomNavigationBar: (pdfPath != null && placements.isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: savePdf,
                  child: const Text("SAVE SIGNED PDF"),
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
