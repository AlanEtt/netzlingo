import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/phrase_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/phrase/phrase_card.dart';
import 'add_phrase_screen.dart';
import 'category_management_screen.dart';

class PhraseManagementScreen extends StatefulWidget {
  const PhraseManagementScreen({Key? key}) : super(key: key);

  @override
  PhraseManagementScreenState createState() => PhraseManagementScreenState();
}

class PhraseManagementScreenState extends State<PhraseManagementScreen> {
  // Filter dan pencarian
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  String? _selectedLanguageId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Memuat frasa saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhrases();
    });
  }

  Future<void> _loadPhrases() async {
    final phraseProvider = Provider.of<PhraseProvider>(context, listen: false);
    await phraseProvider.loadPhrases(
      languageId: _selectedLanguageId,
      categoryId: _selectedCategoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frasa Saya'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
            tooltip: 'Tampilkan favorit saja',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
            tooltip: 'Filter frasa',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ),
              ).then((_) {
                // Refresh kategori setelah kembali dari halaman manajemen kategori
                setState(() {});
              });
            },
            tooltip: 'Kelola Kategori',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari frasa...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.isEmpty) {
                  _loadPhrases();
                } else {
                  Provider.of<PhraseProvider>(context, listen: false)
                      .searchPhrases(value);
                }
              },
            ),
          ),

          // Phrase list
          Expanded(
            child: Consumer<PhraseProvider>(
              builder: (context, phraseProvider, child) {
                if (phraseProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (phraseProvider.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${phraseProvider.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final filteredPhrases = _filterPhrases(phraseProvider.phrases);

                if (filteredPhrases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.translate,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada frasa yang sesuai.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addNewPhrase,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Frasa Baru'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadPhrases,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredPhrases.length,
                    itemBuilder: (context, index) {
                      final phrase = filteredPhrases[index];
                      return PhraseCard(
                        phrase: phrase,
                        onEdit: () => _editPhrase(phrase),
                        onDelete: () => _deletePhrase(phrase),
                        onFavoriteToggle: () => _toggleFavorite(phrase),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPhrase,
        icon: const Icon(Icons.add),
        label: const Text('Frasa Baru'),
      ),
    );
  }

  // Filter frasa berdasarkan kriteria yang dipilih
  List<Phrase> _filterPhrases(List<Phrase> phrases) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      phrases = phrases
          .where((phrase) =>
              phrase.originalText.toLowerCase().contains(query) ||
              phrase.translatedText.toLowerCase().contains(query) ||
              (phrase.notes?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    if (_showFavoritesOnly) {
      phrases = phrases.where((phrase) => phrase.isFavorite).toList();
    }

    return phrases;
  }

  // Dialog untuk filter
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Frasa'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filter bahasa
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Bahasa',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedLanguageId,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Semua Bahasa'),
                            ),
                            ...languageProvider.languages.map((language) {
                              return DropdownMenuItem(
                                value: language.id,
                                child: Text(language.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguageId = value;
                              // Reset kategori jika bahasa berubah
                              _selectedCategoryId = null;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filter kategori
                    Consumer2<CategoryProvider, LanguageProvider>(
                      builder:
                          (context, categoryProvider, languageProvider, child) {
                        // Filter kategori berdasarkan bahasa yang dipilih
                        final filteredCategories = categoryProvider.categories
                            .where(
                              (category) =>
                                  category.languageId == null ||
                                  category.languageId == _selectedLanguageId,
                            )
                            .toList();

                        return DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCategoryId,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Semua Kategori'),
                            ),
                            ...filteredCategories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filter favorit
                    CheckboxListTile(
                      title: const Text('Hanya tampilkan favorit'),
                      value: _showFavoritesOnly,
                      onChanged: (value) {
                        setState(() {
                          _showFavoritesOnly = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Reset'),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _showFavoritesOnly = false;
                      _selectedLanguageId = null;
                      _selectedCategoryId = null;
                    });
                  },
                ),
                ElevatedButton(
                  child: const Text('Terapkan'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Terapkan filter
                    _loadPhrases();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addNewPhrase() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPhraseScreen(),
      ),
    ).then((_) => _loadPhrases());
  }

  void _editPhrase(Phrase phrase) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPhraseScreen(phraseToEdit: phrase),
      ),
    ).then((_) => _loadPhrases());
  }

  void _deletePhrase(Phrase phrase) {
    // Konfirmasi penghapusan
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Frasa'),
        content: Text(
          'Apakah Anda yakin ingin menghapus frasa "${phrase.originalText}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeletePhrase(phrase);
            },
            child: const Text('Hapus'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePhrase(Phrase phrase) async {
    if (phrase.id == null) return;

    final phraseProvider = Provider.of<PhraseProvider>(context, listen: false);
    final success = await phraseProvider.deletePhrase(phrase.id!);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frasa berhasil dihapus')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal menghapus frasa: ${phraseProvider.error}')),
      );
    }
  }

  Future<void> _toggleFavorite(Phrase phrase) async {
    final phraseProvider = Provider.of<PhraseProvider>(context, listen: false);
    await phraseProvider.toggleFavorite(phrase);
  }
}
