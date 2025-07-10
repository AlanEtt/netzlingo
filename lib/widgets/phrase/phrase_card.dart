import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/phrase_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tts_service.dart';

class PhraseCard extends StatefulWidget {
  final Phrase phrase;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const PhraseCard({
    Key? key,
    required this.phrase,
    this.onDeleted,
    this.onUpdated,
  }) : super(key: key);

  @override
  State<PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<PhraseCard> {
  bool _isDeleting = false;
  bool _isUpdating = false;
  final TTSService _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;

    // PERBAIKAN: Tentukan apakah user dapat mengedit/menghapus frasa ini dengan lebih ketat
    final bool canModify =
        currentUserId.isNotEmpty && currentUserId == widget.phrase.userId;

    // PERBAIKAN: Tambahkan notifikasi visual jika frasa bukan milik user
    final bool isUniversal = widget.phrase.userId == 'universal';
    final bool isOtherUserPhrase =
        !canModify && !isUniversal && widget.phrase.userId != currentUserId;

    if (isOtherUserPhrase) {
      print(
          "Warning: Displaying phrase ${widget.phrase.id} owned by ${widget.phrase.userId} to user $currentUserId");
    }

    return Card(
      // PERBAIKAN: Tambahkan border merah jika frasa milik user lain (untuk debugging)
      shape: isOtherUserPhrase
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.red, width: 2.0),
              borderRadius: BorderRadius.circular(4.0),
            )
          : null,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.phrase.originalText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    _ttsService.speak(widget.phrase.originalText);
                  },
                  tooltip: 'Dengarkan',
                ),
                // PERBAIKAN: Tombol favorit hanya berfungsi jika frasa milik user sendiri
                IconButton(
                  icon: Icon(
                    widget.phrase.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  onPressed: canModify ? _toggleFavorite : null,
                  tooltip: canModify
                      ? (widget.phrase.isFavorite
                          ? 'Hapus dari favorit'
                          : 'Tambahkan ke favorit')
                      : 'Hanya pemilik yang dapat mengubah favorit',
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.phrase.translatedText,
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.phrase.notes != null && widget.phrase.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Catatan: ${widget.phrase.notes}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 12.0),
            // Tampilkan tags jika ada
            if (widget.phrase.tags != null && widget.phrase.tags!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                children: widget.phrase.tags!.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.shade100,
                    padding: const EdgeInsets.all(2.0),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12.0),
            // PERBAIKAN: Tampilkan indikator ownership jika frasa dari user lain
            if (isOtherUserPhrase)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Frasa user lain',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            // Tombol Edit & Hapus hanya muncul jika user adalah pemilik frasa
            if (canModify)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Edit'),
                    onPressed: _isDeleting || _isUpdating ? null : _editPhrase,
                  ),
                  const SizedBox(width: 8.0),
                  TextButton.icon(
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.delete, size: 20, color: Colors.red),
                    label: Text(
                      'Hapus',
                      style: TextStyle(
                        color: _isDeleting ? Colors.grey : Colors.red,
                      ),
                    ),
                    onPressed:
                        _isDeleting || _isUpdating ? null : _confirmDelete,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Konfirmasi sebelum menghapus
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus frasa ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePhrase();
            },
          ),
        ],
      ),
    );
  }

  // Menghapus frasa
  Future<void> _deletePhrase() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final phraseProvider =
          Provider.of<PhraseProvider>(context, listen: false);
      final success = await phraseProvider.deletePhrase(widget.phrase.id);

      if (success) {
        // Notifikasi sukses
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Frasa berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Callback ke parent widget jika ada
        if (widget.onDeleted != null) {
          widget.onDeleted!();
        }
      } else {
        // Notifikasi gagal
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(phraseProvider.error ?? 'Gagal menghapus frasa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Tangani error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // Mengedit frasa
  void _editPhrase() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Tampilkan dialog edit
      final TextEditingController originalController =
          TextEditingController(text: widget.phrase.originalText);
      final TextEditingController translatedController =
          TextEditingController(text: widget.phrase.translatedText);
      final TextEditingController notesController =
          TextEditingController(text: widget.phrase.notes);

      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Edit Frasa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: originalController,
                  decoration: const InputDecoration(labelText: 'Teks Asli'),
                ),
                TextField(
                  controller: translatedController,
                  decoration: const InputDecoration(labelText: 'Terjemahan'),
                ),
                TextField(
                  controller: notesController,
                  decoration:
                      const InputDecoration(labelText: 'Catatan (opsional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                Navigator.of(ctx).pop({
                  'originalText': originalController.text,
                  'translatedText': translatedController.text,
                  'notes': notesController.text,
                });
              },
            ),
          ],
        ),
      );

      if (result != null) {
        // Update frasa dengan data baru
        final updatedPhrase = widget.phrase.copyWith(
          originalText: result['originalText'],
          translatedText: result['translatedText'],
          notes: result['notes'],
          updatedAt: DateTime.now(),
        );

        final phraseProvider =
            Provider.of<PhraseProvider>(context, listen: false);
        final success = await phraseProvider.updatePhrase(updatedPhrase);

        if (success) {
          // Notifikasi sukses
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Frasa berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Callback ke parent widget jika ada
          if (widget.onUpdated != null) {
            widget.onUpdated!();
          }
        } else {
          // Notifikasi gagal
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(phraseProvider.error ?? 'Gagal memperbarui frasa'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Tangani error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // Toggle favorit
  void _toggleFavorite() async {
    try {
      final phraseProvider =
          Provider.of<PhraseProvider>(context, listen: false);
      await phraseProvider.toggleFavorite(widget.phrase);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status favorit: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
