import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdftool/core/history_manager.dart';
import 'package:pdftool/models/history_item.dart';
import '../models/pdf_tool.dart';
import 'package:flutter/services.dart';

class ToolActionScreen extends StatefulWidget {
  final PdfTool tool;
  final HistoryManager historyManager;

  const ToolActionScreen({
    super.key,
    required this.tool,
    required this.historyManager,
  });

  @override
  State<ToolActionScreen> createState() => _ToolActionScreenState();
}

class _ToolActionScreenState extends State<ToolActionScreen> {
  static const MethodChannel _channel = MethodChannel('pdftool/pdf');

  List<String> selectedFiles = [];

  final TextEditingController _outputController = TextEditingController(
    text: "pdftool-merged",
  );

  final TextEditingController _startPageController = TextEditingController();

  final TextEditingController _endPageController = TextEditingController();

  final TextEditingController _splitOutputController = TextEditingController(
    text: "pdftool-split",
  );

  // ---------------- FILE PICKER ----------------

  Future<void> _pickFiles({bool append = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: widget.tool.allowMultiple,
    );

    if (result != null) {
      setState(() {
        final files = result.paths.whereType<String>().toList();
        if (append) {
          selectedFiles.addAll(files);
        } else {
          selectedFiles = files;
        }
      });
    }
  }

  // ---------------- VALIDATION ----------------

  bool get _canExecute {
    if (widget.tool.title == "Merge PDF") {
      return selectedFiles.length >= 2;
    }

    if (widget.tool.title == "Split PDF") {
      return _isSplitValid;
    }

    return selectedFiles.isNotEmpty;
  }

  bool get _isSplitValid {
    if (selectedFiles.length != 1) return false;

    final start = int.tryParse(_startPageController.text);
    final end = int.tryParse(_endPageController.text);
    final TextEditingController splitOutputController = TextEditingController(
      text: "pdftool-split",
    );

    if (start == null || end == null) return false;
    if (start < 1) return false;
    if (end < start) return false;
    if (splitOutputController.text.trim().isEmpty) return false;

    return true;
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMerge = widget.tool.title == "Merge PDF";
    final isSplit = widget.tool.title == "Split PDF";

    return Scaffold(
      appBar: AppBar(title: Text(widget.tool.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (selectedFiles.isEmpty)
              _buildInitialPicker(context)
            else
              Expanded(
                child: ListView(
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${selectedFiles.length} FILES",
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => selectedFiles.clear()),
                          child: Text(
                            "CLEAR ALL",
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // FILE CARDS
                    ...selectedFiles.map((file) => _fileCard(context, file)),

                    const SizedBox(height: 20),

                    if (isMerge) _addMoreButton(context),

                    if (isSplit) _splitSection(context),

                    if (isMerge) _outputSection(context),

                    const SizedBox(height: 30),

                    _secureBadge(),
                  ],
                ),
              ),
          ],
        ),
      ),

      // ---------------- EXECUTE BUTTON ----------------
      bottomNavigationBar: selectedFiles.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _canExecute
                      ? () async {
                          try {
                            if (widget.tool.title == "Merge PDF") {
                              final result = await _channel
                                  .invokeMethod('merge', {
                                    'files': selectedFiles,
                                    'outputName': _outputController.text,
                                  });

                              if (!mounted) return;

                              widget.historyManager.addHistory(
                                HistoryItem(
                                  action: "Merge PDF",
                                  outputPath: result ?? "",
                                  dateTime: DateTime.now(),
                                  details:
                                      "${selectedFiles.length} files merged",
                                ),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result ?? "Merge complete"),
                                ),
                              );
                            }

                            if (widget.tool.title == "Split PDF") {
                              final result = await _channel.invokeMethod(
                                'split',
                                {
                                  'inputPath': selectedFiles.first,
                                  'startPage': int.parse(
                                    _startPageController.text,
                                  ),
                                  'endPage': int.parse(_endPageController.text),
                                  'outputName': _splitOutputController.text,
                                },
                              );

                              if (!mounted) return;

                              widget.historyManager.addHistory(
                                HistoryItem(
                                  action: "Split PDF",
                                  outputPath: result ?? "",
                                  dateTime: DateTime.now(),
                                  details:
                                      "Pages ${_startPageController.text}-${_endPageController.text}",
                                ),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result ?? "Split complete"),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      : null,
                  child: Text(widget.tool.title.toUpperCase()),
                ),
              ),
            )
          : null,
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _buildInitialPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => _pickFiles(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colorScheme.outlineVariant, width: 2),
          ),
          child: Center(
            child: Text(
              widget.tool.allowMultiple
                  ? "Select PDF Files"
                  : "Select PDF File",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fileCard(BuildContext context, String path) {
    final colorScheme = Theme.of(context).colorScheme;
    final fileName = path.split('/').last;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf),
          const SizedBox(width: 12),
          Expanded(child: Text(fileName, overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => selectedFiles.remove(path)),
          ),
        ],
      ),
    );
  }

  Widget _addMoreButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickFiles(append: true),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 2,
          ),
        ),
        child: const Text("+ ADD MORE FILES"),
      ),
    );
  }

  Widget _splitSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PAGE RANGE"),
          const SizedBox(height: 20),

          Text(
            "OUTPUT FILENAME",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _splitOutputController,
            decoration: InputDecoration(
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startPageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Start Page"),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: _endPageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "End Page"),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _outputSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _outputController,
        decoration: const InputDecoration(labelText: "Output filename"),
      ),
    );
  }

  Widget _secureBadge() {
    return const Center(
      child: Text(
        "SECURE OFFLINE SESSION ACTIVE",
        style: TextStyle(color: Colors.green),
      ),
    );
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    _outputController.dispose();
    _splitOutputController.dispose();
    super.dispose();
  }
}
