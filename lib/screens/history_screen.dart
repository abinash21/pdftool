import 'package:flutter/material.dart';
import '../core/history_manager.dart';

class HistoryScreen extends StatelessWidget {
  final HistoryManager historyManager;

  const HistoryScreen({super.key, required this.historyManager});

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedBuilder(
            animation: historyManager,
            builder: (_, _) {
              final history = historyManager.history;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "History",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (history.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            historyManager.clearHistory();
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (history.isEmpty)
                    const Expanded(child: Center(child: Text("No history yet")))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (_, index) {
                          final item = history[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.action,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(item.dateTime),
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(item.details),
                                const SizedBox(height: 4),
                                Text(
                                  item.outputPath,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
