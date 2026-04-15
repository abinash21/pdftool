import 'package:flutter/material.dart';
import 'package:pdftool/screens/greyscal_pdf_screen.dart';
import '../core/history_manager.dart';

import 'merge_pdf_screen.dart';
import 'split_pdf_screen.dart';
import 'rotate_pdf_screen.dart';
import 'rearrange_pdf_screen.dart';
import 'pagenumber_pdf_screen.dart';
import 'watermark_pdf_screen.dart';
import 'signature_pdf_screen.dart';
import 'compress_pdf_screen.dart';
import 'repair_pdf_screen.dart';
import 'protect_pdf_screen.dart';
import 'unlock_pdf_screen.dart';
import 'metadata_pdf_screen.dart';
import 'pdf_image_screen.dart';
import 'image_pdf_screen.dart';
import 'pdf_text_screen.dart';

class ToolsScreen extends StatefulWidget {
  final HistoryManager historyManager;

  const ToolsScreen({super.key, required this.historyManager});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allTools = [
    // Edit
    {
      "title": "Merge PDF",
      "icon": Icons.layers,
      "category": "Edit Tools",
      "subtitle": "Combine multiple PDFs",
    },
    {
      "title": "Split PDF",
      "icon": Icons.content_cut,
      "category": "Edit Tools",
      "subtitle": "Separate pages into multiple files",
    },
    {
      "title": "Rotate PDF",
      "icon": Icons.rotate_right,
      "category": "Edit Tools",
      "subtitle": "Rotate PDF pages",
    },
    {
      "title": "Rearrange PDF",
      "icon": Icons.swap_vert,
      "category": "Edit Tools",
      "subtitle": "Rearrange PDF pages",
    },
    {
      "title": "Page Numbers",
      "icon": Icons.tag,
      "category": "Edit Tools",
      "subtitle": "Add page numbers to PDF",
    },
    {
      "title": "Watermark",
      "icon": Icons.text_fields,
      "category": "Edit Tools",
      "subtitle": "Add custom overlays to PDF",
    },
    {
      "title": "Signature",
      "icon": Icons.gesture,
      "category": "Edit Tools",
      "subtitle": "Add digital signatures to PDF",
    },

    // Optimize
    {
      "title": "Compress PDF",
      "icon": Icons.compress,
      "category": "Optimize Tools",
      "subtitle": "Reduce PDF file size",
    },
    {
      "title": "Grayscale",
      "icon": Icons.grain,
      "category": "Optimize Tools",
      "subtitle": "Convert PDF to grayscale",
    },
    {
      "title": "Repair PDF",
      "icon": Icons.bug_report,
      "category": "Optimize Tools",
      "subtitle": "Repair damaged PDF files",
    },

    // Secure
    {
      "title": "Protect PDF",
      "icon": Icons.lock,
      "category": "Secure Tools",
      "subtitle": "Protect PDF with a password",
    },
    {
      "title": "Unlock PDF",
      "icon": Icons.lock_open,
      "category": "Secure Tools",
      "subtitle": "Unlock protected PDF files",
    },
    {
      "title": "Metadata",
      "icon": Icons.info,
      "category": "Secure Tools",
      "subtitle": "View and edit PDF metadata",
    },

    // Convert
    {
      "title": "PDF to Image",
      "icon": Icons.photo,
      "category": "Convert Tools",
      "subtitle": "Convert PDF pages to images",
    },
    {
      "title": "Image to PDF",
      "icon": Icons.insert_photo,
      "category": "Convert Tools",
      "subtitle": "Convert images to PDF",
    },
    {
      "title": "PDF to Text",
      "icon": Icons.text_fields,
      "category": "Convert Tools",
      "subtitle": "Extract text from PDF",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTools = _allTools.where((tool) {
      final query = _searchController.text.toLowerCase();
      return tool["title"].toLowerCase().contains(query);
    }).toList();

    final groupedTools = <String, List<Map<String, dynamic>>>{};

    for (var tool in filteredTools) {
      groupedTools.putIfAbsent(tool["category"], () => []).add(tool);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "All Tools",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              _searchBar(),
              const SizedBox(height: 20),

              /// Tool List
              Expanded(
                child: ListView(
                  children: groupedTools.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ...entry.value.map((tool) {
                          return _toolTile(
                            context,
                            tool["title"],
                            tool["icon"],
                            tool["subtitle"],
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 55,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search for a tool...",
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolTile(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (title == "Merge PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MergePdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Split PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SplitPdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Rotate PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RotatePdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Rearrange PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RearrangePdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Page Numbers") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PageNumbersScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Watermark") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  WatermarkPdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Signature") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SignaturePdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Compress PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CompressPdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Grayscale") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  GreyscalePdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Repair PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RepairPdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Protect PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProtectPdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Unlock PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UnlockPdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Metadata") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MetadataPdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "PDF to Image") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PdfToImageScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "Image to PDF") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ImageToPdfScreen(historyManager: widget.historyManager),
            ),
          );
        } else if (title == "PDF to Text") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PdfToTextScreen(historyManager: widget.historyManager),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
