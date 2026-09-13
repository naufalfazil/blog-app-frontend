import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;

  List categories = [];
  int? _selectedCategoryId;

  bool _isSaving = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _getCategories();
  }

  Future<void> _getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/v1/categories'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          categories = data['data'];
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });

      debugPrint('Error get categories: $e');
    }
  }


  Future<void> _showAddCategoryDialog() async {
  final controller = TextEditingController();

  final categoryName = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Tambah Kategori',
          style: TextStyle(
            fontFamily: 'Comic Relief',
            fontWeight: FontWeight.w400,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nama kategori',
            filled: true,
            fillColor:  Color.fromARGB(255, 237, 230, 230),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
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
              foregroundColor: const Color(0xFFB06D50),
              side: const BorderSide(
                color: Color(0xFFB06D50),
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Comic Relief'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();

              if (name.isEmpty) return;

              Navigator.pop(context, name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB06D50),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Tambah',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Comic Relief',
                ),
            ),
          ),
        ],
      );
    },
  );

  controller.dispose();
  if (categoryName == null || categoryName.isEmpty) return;
  try {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/v1/categories'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': categoryName,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
      await _getCategories();

      final data = jsonDecode(response.body);
      final newCategoryId = data['data']?['id'];
      setState(() {
        if (newCategoryId != null) {
          _selectedCategoryId = newCategoryId;
        } else {
          final newCategory = categories.firstWhere(
            (category) =>
                category['name'].toString().toLowerCase() ==
                categoryName.toLowerCase(),
            orElse: () => null,
          );

          if (newCategory != null) {
            _selectedCategoryId = newCategory['id'];
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil ditambahkan'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menambahkan kategori (${response.statusCode})',
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terjadi kesalahan saat menambahkan kategori'),
      ),
    );

    debugPrint('Error add category: $e');
  }
}


  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Gagal memilih gambar: $e');
    }
  }

  Future<void> _createPost() async {
    if (_isSaving) return;

    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty ||
        _selectedImage == null ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/api/v1/posts'),
      );

      request.fields['categoryId'] =
          _selectedCategoryId.toString();

      request.fields['title'] = _titleController.text.trim();
      request.fields['content'] = _contentController.text.trim();

      final bytes = await _selectedImage!.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _selectedImage!.name,
        ),
      );

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artikel berhasil dibuat'),
          ),
        );

        Navigator.pop(context, true);
      } else {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuat artikel (${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat membuat artikel'),
        ),
      );

      debugPrint('Error create post: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),

        title: const Text(
          'Create Artikel',
          style: TextStyle(
            fontFamily: 'Comic Relief',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _createPost,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFB06D50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Comic Relief',
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _selectedImage != null
                    ? Image.network(
                        _selectedImage!.path,
                        width: double.infinity,
                        height: 340,
                        fit: BoxFit.cover,
                      )
                    : _imagePlaceholder(),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Tap gambar untuk menambahkan foto',
                style: TextStyle(
                  fontFamily: 'Comic Relief',
                  color: Color(0xFFB06D50),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // TITLE
            const Text(
              'Title',
              style: TextStyle(
                fontFamily: 'Comic Relief',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontFamily: 'Comic Relief',
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Article Title',
                hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 90, 90, 90),
                ),
                filled: true,
                fillColor: Color.fromARGB(255, 237, 230, 230),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // CATEGORY
            const Text(
              'Category',
              style: TextStyle(
                fontFamily: 'Comic Relief',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _isLoadingCategories
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 237, 230, 230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    hint: const Text(
                      'Pilih kategori',
                      style: TextStyle(
                        color: Color.fromARGB(255, 90, 90, 90),
                      ),
                      ),
                    items: [
                      ...categories.map<DropdownMenuItem<int>>(
                        (category) {
                          return DropdownMenuItem<int>(
                            value: category['id'],
                            child: Text(
                              category['name'] ?? 'Tanpa Nama',
                              style: TextStyle(
                                fontFamily: 'Comic Relief',
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                      const DropdownMenuItem<int>(
                        value: -1,
                        child: Text(
                          '+ Tambah kategori',
                          style: TextStyle(
                            color: Color(0xFFB06D50),
                            fontFamily: 'Comic Relief',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == -1) {
                        await _showAddCategoryDialog();
                        return;
                      }

                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                  
            const SizedBox(height: 24),

            // ARTICLE
            const Text(
              'Article',
              style: TextStyle(
                fontFamily: 'Comic Relief',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _contentController,
              maxLines: 14,
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 16,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Write your article here...',
                hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 90, 90, 90),
                ),
                filled: true,
                fillColor: Color.fromARGB(255, 237, 230, 230),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 240,
      color: Color.fromARGB(255, 237, 230, 230),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 55,
              color: Color.fromARGB(255, 90, 90, 90),
            ),
            SizedBox(height: 10),
            Text(
              'Add article cover image',
              style: TextStyle(
                color: Color.fromARGB(255, 90, 90, 90),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}