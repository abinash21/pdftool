import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import '../core/history_manager.dart';
import 'package:pdftool/models/history_item.dart';

class WatermarkPdfScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const WatermarkPdfScreen({super.key, required this.historyManager});

  @override
  State<WatermarkPdfScreen> createState() => _WatermarkPdfScreenState();
}

class _WatermarkPdfScreenState extends State<WatermarkPdfScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  String? pdfPath;
  pdfx.PdfDocument? previewDocument;
  pdfx.PdfPageImage? currentPageImage;
  bool isLoading = false;

  // Watermark parameters with default values
  String watermarkText = "CONFIDENTIAL";
  Color watermarkColor = Colors.red;
  double opacity = 30.0; // Slider value (0-100)
  double size = 50.0; // Slider value
  double rotation = -45.0; // Slider value (-180 to 180)

  final TextEditingController textController = TextEditingController(
    text: "CONFIDENTIAL",
  );
  final TextEditingController outputController = TextEditingController(
    text: "watermarked_pdf",
  );

  // Predefined color choices
  final List<Color> watermarkColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    textController.addListener(() {
      setState(() {
        watermarkText = textController.text;
      });
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => isLoading = true);

    pdfPath = result.files.single.path!;
    outputController.text =
        "${result.files.single.name.replaceAll('.pdf', '')}-watermarked";

    try {
      previewDocument = await pdfx.PdfDocument.openFile(pdfPath!);
      // Renders first page for preview
      final page = await previewDocument!.getPage(1);
      currentPageImage = await page.render(
        width: page.width,
        height: page.height,
      );
      await page.close();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening PDF: $e")));
      closeFile(); // Resets on error
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> savePdf() async {
    if (pdfPath == null) return;

    try {
      final result = await _channel.invokeMethod('addWatermark', {
        'inputPath': pdfPath,
        'text': watermarkText,
        'color': watermarkColor.value,
        'opacity': opacity / 100.0, // Convert to range 0.0 - 1.0
        'size': size,
        'rotation': rotation,
        'outputName': outputController.text,
      });

      if (!mounted) return;

      widget.historyManager.addHistory(
        HistoryItem(
          action: "Apply Watermark",
          outputPath: result ?? "",
          dateTime: DateTime.now(),
          details: "Text: '$watermarkText', Opacity: ${opacity.toInt()}%",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "Watermark applied successfully")),
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
      previewDocument?.close();
      previewDocument = null;
      currentPageImage = null;
    });
  }

  void _showCustomColorDialog() {
    final TextEditingController hexController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Custom Hex Color",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: hexController,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: "#FFFFFF",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                String hex = hexController.text.trim().toUpperCase();
                // Remove the hash if they typed it
                if (hex.startsWith("#")) {
                  hex = hex.substring(1);
                }

                // If it's a standard 6-character hex, add full opacity (FF) to the front
                if (hex.length == 6) {
                  hex = "FF$hex";
                }

                try {
                  // Attempt to parse the hex string to an integer
                  Color newColor = Color(int.parse(hex, radix: 16));
                  setState(() {
                    watermarkColor = newColor;
                  });
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Invalid Hex Code. Try format like #FF0000",
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                "APPLY",
                style: TextStyle(
                  color: Color(0xFFFF3366),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
              Text("Loading PDF for preview..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Watermark",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
                    /// FILE CARD - Replicated from user original code
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
                            onPressed: closeFile,
                          ),
                        ],
                      ),
                    ),

                    /// SCROLLABLE SETTINGS AREA
                    Expanded(
                      child: ListView(
                        children: [
                          /// PDF LIVE PREVIEW AREA with Custom Painter for watermark overlay
                          if (currentPageImage != null)
                            Container(
                              height: 300,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                                color: Colors.white,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  Center(
                                    child: Image.memory(
                                      currentPageImage!.bytes,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // Live watermark overlay
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Calculate relative font size based on preview scale vs native page size
                                      double scaleX =
                                          constraints.maxWidth /
                                          currentPageImage!.width!;
                                      double scaleY =
                                          constraints.maxHeight /
                                          currentPageImage!.height!;
                                      double scale = math.min(scaleX, scaleY);
                                      double scaledFontSize = size * scale;

                                      return Center(
                                        child: Transform.rotate(
                                          angle: rotation * math.pi / 180,
                                          child: Text(
                                            watermarkText,
                                            style: TextStyle(
                                              color: watermarkColor.withOpacity(
                                                opacity / 100.0,
                                              ),
                                              fontSize: scaledFontSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                          // WATERMARK TEXT INPUT
                          TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              labelText: "Watermark Text",
                            ),
                          ),
                          const SizedBox(height: 24),

                          // APPEARANCE SECTION
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "APPEARANCE",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.palette_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Handle custom color picker - could open another dialog.
                                  // For simplicity here, just printing.
                                  print("Open full color picker dialog");
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // COLOR PICKER GRID (replicated from image_1.png)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount:
                                watermarkColors.length +
                                1, // Predefined + custom placeholder
                            itemBuilder: (context, index) {
                              if (index < watermarkColors.length) {
                                final color = watermarkColors[index];
                                final isSelected = watermarkColor == color;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => watermarkColor = color),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: colorScheme.primary,
                                              width: 3,
                                            )
                                          : Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ), // Ring effect like image_1.png
                                    ),
                                  ),
                                );
                              } else {
                                return GestureDetector(
                                  onTap: _showCustomColorDialog,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.colorize,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // SLIDERS: OPACITY, SIZE, ROTATION (replicated from image_1.png)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "OPACITY (${opacity.toInt()}%)",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "SIZE (${size.toInt()}PX)",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: opacity,
                                  min: 0.0,
                                  max: 100.0,
                                  onChanged: (value) =>
                                      setState(() => opacity = value),
                                  activeColor: Colors
                                      .pinkAccent, // Matching theme in image_1.png
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Slider(
                                  value: size,
                                  min: 10.0,
                                  max: 100.0,
                                  onChanged: (value) =>
                                      setState(() => size = value),
                                  activeColor: Colors.pinkAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ROTATION SLIDER
                          Text(
                            "ROTATION (${rotation.toInt()}°)",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: rotation,
                            min: -180.0,
                            max: 180.0,
                            onChanged: (value) =>
                                setState(() => rotation = value),
                            activeColor: Colors.pinkAccent,
                          ),
                          const SizedBox(height: 24),

                          // OUTPUT FILENAME INPUT
                          TextField(
                            controller: outputController,
                            decoration: const InputDecoration(
                              labelText: "Output Filename",
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
                  child: const Text("APPLY WATERMARK"),
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    textController.dispose();
    outputController.dispose();
    previewDocument?.close();
    super.dispose();
  }
}
