import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../models/tag.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/tts_service.dart';

class PhraseCard extends StatelessWidget {
  final Phrase phrase;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onFavoriteToggle;

  const PhraseCard({
    Key? key,
    required this.phrase,
    this.onEdit,
    this.onDelete,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    phrase.originalText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    TTSService().speak(phrase.originalText);
                  },
                  tooltip: 'Ucapkan',
                ),
                if (onFavoriteToggle != null)
                  IconButton(
                    icon: Icon(
                      phrase.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: phrase.isFavorite ? Colors.red : null,
                    ),
                    onPressed: onFavoriteToggle,
                    tooltip: phrase.isFavorite
                        ? 'Hapus dari favorit'
                        : 'Tambahkan ke favorit',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              phrase.translatedText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (phrase.notes != null && phrase.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Catatan: ${phrase.notes}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
              ),
            ],

            // Kategori
            if (phrase.categoryId != null)
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  return FutureBuilder<Category?>(
                    future:
                        categoryProvider.getCategoryById(phrase.categoryId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox.shrink();
                      }

                      final category = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.folder,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              category.name,
                              style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

            // Tag
            Consumer<TagProvider>(builder: (context, tagProvider, child) {
              return FutureBuilder<List<Tag>>(
                future: phrase.id != null
                    ? tagProvider.getTagsForPhrase(phrase.id!, '')
                    : Future.value([]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final tags = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags.map((tag) {
                        final tagColor =
                            _getColorFromHex(tag.color ?? '#E0E0E0');
                        return Chip(
                          label: Text(
                            tag.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: tagColor.withOpacity(0.2),
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            }),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Hapus'),
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    }
    return Colors.grey;
  }
}
