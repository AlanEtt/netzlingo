import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../models/tag.dart';
import '../../providers/phrase_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/async_helper.dart';
import '../../widgets/phrase/tag_input_widget.dart';
import 'category_management_screen.dart';

class AddPhraseScreen extends StatefulWidget {
  final Phrase? phraseToEdit; // Jika ada, berarti mode edit

  const AddPhraseScreen({Key? key, this.phraseToEdit}) : super(key: key);

  @override
  AddPhraseScreenState createState() => AddPhraseScreenState();
}

class AddPhraseScreenState extends State<AddPhraseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originalTextController = TextEditingController();
  final _translatedTextController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedLanguageId; // Sesuaikan dengan tipe data di model
  String? _selectedCategoryId; // Sesuaikan dengan tipe data di model
  bool _isFavorite = false;
  bool _isLoading = false;
  String? _error;
  List<Tag> _selectedTags = [];

  @override
  void initState() {
    super.initState();

    // Jika mode edit, isi field dengan data yang ada
    if (widget.phraseToEdit != null) {
      _originalTextController.text = widget.phraseToEdit!.originalText;
      _translatedTextController.text = widget.phraseToEdit!.translatedText;
      _notesController.text = widget.phraseToEdit!.notes ?? '';
      _selectedLanguageId = widget.phraseToEdit!.languageId;
      _selectedCategoryId = widget.phraseToEdit!.categoryId;
      _isFavorite = widget.phraseToEdit!.isFavorite;

      // Memuat tag yang sudah ada untuk frasa ini
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.phraseToEdit?.id != null) {
          _loadTagsForPhrase(widget.phraseToEdit!.id!);
        }
      });
    }

    // Memuat bahasa dan kategori
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      Provider.of<LanguageProvider>(context, listen: false).loadLanguages();
      Provider.of<CategoryProvider>(context, listen: false)
          .loadCategories(userId: userId);
      Provider.of<TagProvider>(context, listen: false).loadTags(userId);
    });
  }

  Future<void> _loadTagsForPhrase(String phraseId) async {
    // Gunakan AsyncHelper untuk memastikan operasi aman
    AsyncHelper.safeSetState(
      state: this,
      operation: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final tagProvider = Provider.of<TagProvider>(context, listen: false);
        return await tagProvider.getTagsForPhrase(
            phraseId, authProvider.userId);
      },
      setStateCallback: (tags) {
        _selectedTags = tags;
      },
      onError: (error) {
        print("Error loading tags for phrase: $error");
      },
    );
  }

  @override
  void dispose() {
    _originalTextController.dispose();
    _translatedTextController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.phraseToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Frasa' : 'Tambah Frasa Baru'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Dropdown bahasa
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        if (languageProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Bahasa',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedLanguageId,
                          items: languageProvider.languages.map((language) {
                            return DropdownMenuItem(
                              value: language.id,
                              child: Text(language.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedLanguageId = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Pilih bahasa';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown kategori
                    Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        return DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: 'Kategori (opsional)',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CategoryManagementScreen(),
                                  ),
                                ).then((_) {
                                  // Refresh kategori setelah kembali
                                  final authProvider =
                                      Provider.of<AuthProvider>(context,
                                          listen: false);
                                  categoryProvider.loadCategories(
                                      userId: authProvider.userId,
                                      languageId: _selectedLanguageId);
                                });
                              },
                              tooltip: 'Tambah Kategori',
                            ),
                          ),
                          value: _selectedCategoryId,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Tanpa Kategori')),
                            ...categoryProvider.categories
                                .where((category) =>
                                    category.languageId == null ||
                                    category.languageId == _selectedLanguageId)
                                .map((category) {
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

                    // Text field untuk teks asli
                    TextFormField(
                      controller: _originalTextController,
                      decoration: const InputDecoration(
                        labelText: 'Teks Asli',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Teks asli harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Text field untuk terjemahan
                    TextFormField(
                      controller: _translatedTextController,
                      decoration: const InputDecoration(
                        labelText: 'Terjemahan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Terjemahan harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Text field untuk catatan
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Tag input widget
                    Consumer<TagProvider>(
                      builder: (context, tagProvider, child) {
                        return TagInputWidget(
                          initialTags: _selectedTags,
                          availableTags: tagProvider.tags,
                          onTagsChanged: (tags) {
                            setState(() {
                              _selectedTags = tags;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Checkbox untuk favorit
                    CheckboxListTile(
                      title: const Text('Tandai sebagai favorit'),
                      value: _isFavorite,
                      onChanged: (value) {
                        setState(() {
                          _isFavorite = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

                    // Tombol simpan
                    ElevatedButton(
                      onPressed: _savePhrase,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        isEditing ? 'Simpan Perubahan' : 'Tambahkan Frasa',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _savePhrase() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final phraseProvider =
            Provider.of<PhraseProvider>(context, listen: false);
        final tagProvider = Provider.of<TagProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (_selectedLanguageId == null) {
          setState(() {
            _error = 'Pilih bahasa terlebih dahulu';
            _isLoading = false;
          });
          return;
        }

        final phrase = Phrase(
          id: widget.phraseToEdit?.id ?? '',
          originalText: _originalTextController.text.trim(),
          translatedText: _translatedTextController.text.trim(),
          languageId: _selectedLanguageId!,
          categoryId: _selectedCategoryId,
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
          isFavorite: _isFavorite,
          userId: authProvider.userId,
          createdAt: widget.phraseToEdit?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        Phrase? savedPhrase;
        if (widget.phraseToEdit == null) {
          // Mode tambah frasa baru
          savedPhrase = await phraseProvider.addPhrase(phrase);
        } else {
          // Mode edit frasa
          final success = await phraseProvider.updatePhrase(phrase);
          if (success) {
            savedPhrase = phrase;
          }
        }

        // Jika berhasil menyimpan frasa, simpan juga tag-nya
        if (savedPhrase != null && savedPhrase.id != null) {
          await tagProvider.saveTagsForPhrase(
            savedPhrase.id!,
            authProvider.userId,
            _selectedTags,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.phraseToEdit == null
                    ? 'Frasa berhasil ditambahkan'
                    : 'Frasa berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          setState(() {
            _error = 'Gagal menyimpan frasa';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
}
