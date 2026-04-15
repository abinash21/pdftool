import 'package:flutter/material.dart';
import 'package:pdftool/core/history_manager.dart';
import '../core/theme_controller.dart';
import 'merge_pdf_screen.dart';
import 'split_pdf_screen.dart';
import 'compress_pdf_screen.dart';
import 'protect_pdf_screen.dart';

class HomeScreen extends StatelessWidget {
  final ThemeController themeController;
  final VoidCallback onMoreEnginesTap;
  final HistoryManager historyManager;

  const HomeScreen({
    super.key,
    required this.themeController,
    required this.onMoreEnginesTap,
    required this.historyManager,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final topColor = isDark ? Colors.black : Colors.grey.shade100;
    final bottomColor = isDark ? const Color(0xFF140000) : Colors.pink.shade50;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [topColor, bottomColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PDFTool",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      onPressed: () {
                        themeController.setTheme(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      const SizedBox(height: 30),

                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MergePdfScreen(
                                    historyManager: historyManager,
                                  ),
                                ),
                              );
                            },
                            child: _card(
                              context,
                              "Merge",
                              "Combine multiple PDFs",
                              Icons.layers,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CompressPdfScreen(
                                    historyManager: historyManager,
                                  ), // Fixed
                                ),
                              );
                            },
                            child: _card(
                              context,
                              "Compress",
                              "Reduce file size",
                              Icons.flash_on,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SplitPdfScreen(
                                    historyManager: historyManager,
                                  ), // Fixed
                                ),
                              );
                            },
                            child: _card(
                              context,
                              "Split",
                              "Separate pages",
                              Icons.content_cut,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProtectPdfScreen(
                                    historyManager: historyManager,
                                  ), // Fixed
                                ),
                              );
                            },
                            child: _card(
                              context,
                              "Protect",
                              "Secure with password",
                              Icons.lock,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      GestureDetector(
                        onTap: onMoreEnginesTap,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "More Engines",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "FULL CATALOG",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(letterSpacing: 1.2),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    String subTitle,
    IconData icon,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
            shadows: [
              Shadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(title, style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 4),

          Text(
            subTitle,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
