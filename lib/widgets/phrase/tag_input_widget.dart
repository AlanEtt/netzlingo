import 'package:flutter/material.dart';
import '../../models/tag.dart';

class TagInputWidget extends StatefulWidget {
  final List<Tag> initialTags;
  final List<Tag> availableTags;
  final Function(List<Tag>) onTagsChanged;

  const TagInputWidget({
    Key? key,
    required this.initialTags,
    required this.availableTags,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  TagInputWidgetState createState() => TagInputWidgetState();
}

class TagInputWidgetState extends State<TagInputWidget> {
  late List<Tag> _selectedTags;
  final TextEditingController _tagController = TextEditingController();
  List<Tag> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
    _filteredTags = List.from(widget.availableTags);
  }

  @override
  void didUpdateWidget(TagInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTags != widget.initialTags ||
        oldWidget.availableTags != widget.availableTags) {
      _selectedTags = List.from(widget.initialTags);
      _filteredTags = List.from(widget.availableTags);
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _filterTags(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTags = widget.availableTags
            .where((tag) => !_selectedTags.any((t) => t.id == tag.id))
            .toList();
      });
      return;
    }

    setState(() {
      _filteredTags = widget.availableTags
          .where((tag) =>
              !_selectedTags.any((t) => t.id == tag.id) &&
              tag.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addTag(Tag tag) {
    setState(() {
      _selectedTags.add(tag);
      _tagController.clear();
      _filterTags('');
    });
    widget.onTagsChanged(_selectedTags);
  }

  void _createNewTag(String tagName) {
    if (tagName.isEmpty) return;

    // Cek apakah tag sudah ada dalam available tags
    final existingTag = widget.availableTags
        .where((tag) => tag.name.toLowerCase() == tagName.toLowerCase())
        .toList();

    if (existingTag.isNotEmpty) {
      // Jika sudah ada, tambahkan tag yang sudah ada
      _addTag(existingTag.first);
    } else {
      // Jika belum ada, buat tag baru
      final newTag = Tag(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: tagName,
        color: _getRandomColor(),
        userId: '', // Ini akan diisi saat disimpan ke database
        createdAt: DateTime.now(),
      );
      _addTag(newTag);
    }

    _tagController.clear();
    _filterTags('');
  }

  String _getRandomColor() {
    // Daftar warna untuk tag baru
    final colors = [
      '#FF5252', // Merah
      '#FF4081', // Pink
      '#E040FB', // Ungu
      '#7C4DFF', // Ungu tua
      '#536DFE', // Indigo
      '#448AFF', // Biru
      '#40C4FF', // Biru muda
      '#18FFFF', // Cyan
      '#64FFDA', // Teal
      '#69F0AE', // Hijau
      '#B2FF59', // Lime
      '#EEFF41', // Kuning
      '#FFD740', // Amber
      '#FFAB40', // Oranye
      '#FF6E40', // Oranye tua
    ];

    return colors[DateTime.now().microsecond % colors.length];
  }

  void _removeTag(Tag tag) {
    setState(() {
      _selectedTags.removeWhere((t) => t.id == tag.id);
      _filterTags(_tagController.text);
    });
    widget.onTagsChanged(_selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Tag',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Selected tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedTags.map((tag) {
            return Chip(
              label: Text(tag.name),
              backgroundColor: _getColorFromHex(tag.color ?? '#E0E0E0'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeTag(tag),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Input for new tag
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan tag...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: _filterTags,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _createNewTag(value);
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_tagController.text.isNotEmpty) {
                  _createNewTag(_tagController.text);
                }
              },
            ),
          ],
        ),

        // Filtered available tags
        if (_filteredTags.isNotEmpty && _tagController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredTags.length,
              itemBuilder: (context, index) {
                final tag = _filteredTags[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  title: Text(tag.name),
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: _getColorFromHex(tag.color ?? '#E0E0E0'),
                    child: const SizedBox(),
                  ),
                  onTap: () => _addTag(tag),
                );
              },
            ),
          ),
      ],
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
