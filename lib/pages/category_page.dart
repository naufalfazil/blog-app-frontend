import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'article_detail_page.dart';

class CategoryPage extends StatefulWidget {
  final VoidCallback? onBack;

  const CategoryPage({
    super.key,
    this.onBack,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List categories = [];
  List articles = [];

  int? _selectedCategoryId;
  bool _isLoading = true;

  final Color _primaryColor =
      const Color.fromARGB(255, 157, 98, 40);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categoryResponse = await http.get(
        Uri.parse(
          'http://localhost:3000/api/v1/categories',
        ),
      );

      final articleResponse = await http.get(
        Uri.parse(
          'http://localhost:3000/api/v1/posts',
        ),
      );

      if (!mounted) return;

      if (categoryResponse.statusCode == 200 &&
          articleResponse.statusCode == 200) {
        final categoryData =
            jsonDecode(categoryResponse.body);
        final articleData =
            jsonDecode(articleResponse.body);

        final loadedCategories =
            categoryData['data'] ?? [];
        final loadedArticles =
            articleData['data'] ?? [];

        int? selectedId = _selectedCategoryId;

        if (loadedCategories.isEmpty) {
          selectedId = null;
        } else {
          final exists = loadedCategories.any(
            (category) =>
                category['id'] == selectedId,
          );

          if (!exists) {
            selectedId =
                loadedCategories[0]['id'];
          }
        }

        setState(() {
          categories = loadedCategories;
          articles = loadedArticles;
          _selectedCategoryId = selectedId;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        'Error load category page: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal memuat data',
          ),
        ),
      );
    }
  }

  List get _filteredArticles {
    if (_selectedCategoryId == null) {
      return [];
    }

    return articles.where((article) {
      return article['categoryId'] ==
          _selectedCategoryId;
    }).toList();
  }

  String get _selectedCategoryName {
    if (_selectedCategoryId == null) {
      return '';
    }

    for (final category in categories) {
      if (category['id'] ==
          _selectedCategoryId) {
        return category['name'] ?? '';
      }
    }

    return '';
  }

  Future<void> _editCategory(
    Map category,
  ) async {
    final controller = TextEditingController(
      text: category['name'] ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit Kategori',
            style: TextStyle(
              fontFamily: 'Comic Relief',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nama kategori',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(
                  color: _primaryColor,
                  width: 2,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Comic Relief',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name =
                    controller.text.trim();

                if (name.isEmpty) return;

                Navigator.pop(context, name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(
                  fontFamily: 'Comic Relief',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null ||
        newName.isEmpty) {
      return;
    }

    try {
      final id = category['id'];

      final response = await http.put(
        Uri.parse(
          'http://localhost:3000/api/v1/categories/$id',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': newName,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _loadData();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kategori berhasil diperbarui',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui kategori '
              '(${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'Error edit category: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Terjadi kesalahan saat mengedit kategori',
          ),
        ),
      );
    }
  }

  Future<void> _deleteCategory(
    Map category,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Kategori?',
            style: TextStyle(
              fontFamily: 'Comic Relief',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Apakah kamu yakin ingin menghapus '
            'kategori "${category['name']}"?',
            style: const TextStyle(
              fontFamily: 'Comic Relief',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(
                  color: _primaryColor,
                  width: 2,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Comic Relief',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontFamily: 'Comic Relief',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final id = category['id'];

      final response = await http.delete(
        Uri.parse(
          'http://localhost:3000/api/v1/categories/$id',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _loadData();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kategori berhasil dihapus',
            ),
          ),
        );
      } else if (response.statusCode == 400 ||
          response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kategori tidak dapat dihapus '
              'karena masih digunakan oleh artikel',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus kategori '
              '(${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'Error delete category: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Terjadi kesalahan saat menghapus kategori',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        255,
        250,
        255,
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
          255,
          255,
          250,
          255,
        ),
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
        title: const Text(
          'Category',
          style: TextStyle(
            fontFamily: 'Comic Relief',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // CATEGORY BUTTONS
                  SizedBox(
                    height: 48,
                    child: categories.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada kategori',
                              style: TextStyle(
                                fontFamily:
                                    'Comic Relief',
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 20,
                            ),
                            scrollDirection:
                                Axis.horizontal,
                            itemCount:
                                categories.length,
                            separatorBuilder:
                                (context, index) {
                              return const SizedBox(
                                width: 10,
                              );
                            },
                            itemBuilder:
                                (context, index) {
                              final category =
                                  categories[index];

                              final isSelected =
                                  _selectedCategoryId ==
                                      category['id'];

                              return _categoryButton(
                                category,
                                isSelected,
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 18),

                  // SELECTED CATEGORY
                  if (_selectedCategoryId !=
                      null)
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCategoryName,
                              style:
                                  const TextStyle(
                                fontFamily:
                                    'Comic Relief',
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          // EDIT
                          CircleAvatar(
                            backgroundColor:
                                _primaryColor,
                            child: IconButton(
                              onPressed: () {
                                final category =
                                    categories.firstWhere(
                                  (category) =>
                                      category['id'] ==
                                      _selectedCategoryId,
                                );

                                _editCategory(
                                  category,
                                );
                              },
                              icon: const Icon(
                                Icons.edit_rounded,
                              ),
                              color: const Color
                                  .fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ),
                              tooltip: 'Edit',
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          // DELETE
                          CircleAvatar(
                            backgroundColor:
                                _primaryColor,
                            child: IconButton(
                              onPressed: () {
                                final category =
                                    categories.firstWhere(
                                  (category) =>
                                      category['id'] ==
                                      _selectedCategoryId,
                                );

                                _deleteCategory(
                                  category,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_rounded,
                              ),
                              color: const Color
                                  .fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ),
                              tooltip: 'Hapus',
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 18),

                  // ARTICLES
                  Expanded(
                    child: _filteredArticles
                            .isEmpty
                        ? ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(
                                height: 100,
                              ),
                              Center(
                                child: Text(
                                  'Belum ada artikel '
                                  'di kategori ini',
                                  style: TextStyle(
                                    fontFamily:
                                        'Comic Relief',
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              20,
                              0,
                              20,
                              20,
                            ),
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                _filteredArticles
                                    .length,
                            separatorBuilder:
                                (context, index) {
                              return const SizedBox(
                                height: 18,
                              );
                            },
                            itemBuilder:
                                (context, index) {
                              return _articleItem(
                                _filteredArticles[
                                    index],
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _categoryButton(
    Map category,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId =
              category['id'];
        });
      },
      child: Container(
        height: 42,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor
              : Colors.transparent,
          border: Border.all(
            color: _primaryColor,
            width: 1.5,
          ),
          borderRadius:
              BorderRadius.circular(24),
        ),
        child: Text(
          category['name'] ??
              'Tanpa Nama',
          style: TextStyle(
            fontFamily: 'Comic Relief',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : _primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _articleItem(Map article) {
    final imageUrl =
        article['imageUrl'] ?? '';
    final title =
        article['title'] ?? 'Tanpa Judul';

    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: () async {
        final result =
            await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ArticleDetailPage(
              article: article,
            ),
          ),
        );

        if (result == true) {
          _loadData();
        }
      },
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius:
                BorderRadius.circular(14),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 155,
                    height: 155,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _articleImagePlaceholder();
                    },
                  )
                : _articleImagePlaceholder(),
          ),

          const SizedBox(width: 16),

          // TITLE + DATE
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily:
                        'Comic Relief',
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _formatDate(
                    article['createdAt'],
                  ),
                  style:
                      const TextStyle(
                    fontFamily:
                        'Comic Relief',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _articleImagePlaceholder() {
    return Container(
      width: 155,
      height: 155,
      color: const Color.fromARGB(
        255,
        237,
        230,
        230,
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Color.fromARGB(
          255,
          90,
          90,
          90,
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    try {
      final parsedDate =
          DateTime.parse(
        date.toString(),
      );

      return '${parsedDate.day}/'
          '${parsedDate.month}/'
          '${parsedDate.year}';
    } catch (_) {
      return '';
    }
  }
}