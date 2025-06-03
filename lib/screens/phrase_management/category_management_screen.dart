import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedLanguageId;
  String? _editingCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.loadCategories(userId: authProvider.userId);
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedLanguageId = null;
    _editingCategoryId = null;
  }

  void _editCategory(Category category) {
    setState(() {
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
      _selectedLanguageId = category.languageId;
      _editingCategoryId = category.id;
    });
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState?.validate() != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    final category = Category(
      id: _editingCategoryId ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text.trim(),
      languageId: _selectedLanguageId,
      userId: authProvider.userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success = false;
    if (_editingCategoryId == null) {
      // Tambah kategori baru
      final newCategory = await categoryProvider.addCategory(category);
      success = newCategory != null;
    } else {
      // Update kategori yang ada
      success = await categoryProvider.updateCategory(category);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingCategoryId == null
              ? 'Kategori berhasil ditambahkan'
              : 'Kategori berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus kategori ini? '
          'Frasa yang terkait dengan kategori ini tidak akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    final success = await categoryProvider.deleteCategory(id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      // Jika menghapus kategori yang sedang diedit, reset form
      if (_editingCategoryId == id) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Form tambah/edit kategori
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _editingCategoryId == null
                            ? 'Tambah Kategori Baru'
                            : 'Edit Kategori',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Kategori',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama kategori tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Consumer<LanguageProvider>(
                        builder: (context, languageProvider, child) {
                          return DropdownButtonFormField<String?>(
                            value: _selectedLanguageId,
                            decoration: const InputDecoration(
                              labelText: 'Bahasa (Opsional)',
                              border: OutlineInputBorder(),
                            ),
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
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_editingCategoryId != null)
                            TextButton(
                              onPressed: _resetForm,
                              child: const Text('Batal'),
                            )
                          else
                            const SizedBox.shrink(),
                          ElevatedButton(
                            onPressed: _saveCategory,
                            child: Text(
                              _editingCategoryId == null
                                  ? 'Tambah Kategori'
                                  : 'Simpan Perubahan',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (categoryProvider.categories.isEmpty) {
                    return const Center(
                      child: Text(
                          'Belum ada kategori. Silakan tambahkan kategori baru.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: categoryProvider.categories.length,
                    itemBuilder: (context, index) {
                      final category = categoryProvider.categories[index];
                      return Card(
                        child: ListTile(
                          title: Text(category.name),
                          subtitle: category.description != null
                              ? Text(category.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editCategory(category),
                                tooltip: 'Edit Kategori',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteCategory(category.id),
                                tooltip: 'Hapus Kategori',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
