import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditPostPage extends StatefulWidget {
  final Map article;

  const EditPostPage({
    super.key,
    required this.article,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.article['title'] ?? '';
    _contentController.text = widget.article['content'] ?? '';
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

  Future<void> _updatePost() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final int id = widget.article['id'];

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://localhost:3000/api/v1/posts/$id'),
      );

      request.fields['categoryId'] =
          widget.article['categoryId'].toString();

      request.fields['title'] = _titleController.text;
      request.fields['content'] = _contentController.text;

      // Kalau user memilih gambar baru
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: _selectedImage!.name,
          ),
        );
      }

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artikel berhasil diperbarui'),
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
              'Gagal memperbarui artikel (${response.statusCode})',
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
          content: Text('Terjadi kesalahan saat menyimpan'),
        ),
      );

      debugPrint('Error update post: $e');
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
    final String oldImage = widget.article['imageUrl'] ?? '';

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
          'Edit Artikel',
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
              onPressed: _isSaving ? null : _updatePost,
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
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // GAMBAR
            // =========================
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
                    : oldImage.isNotEmpty
                        ? Image.network(
                            oldImage,
                            width: double.infinity,
                            height: 340,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return _imagePlaceholder();
                            },
                          )
                        : _imagePlaceholder(),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Tap gambar untuk mengganti foto',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =========================
            // TITLE
            // =========================
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
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
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

            // =========================
            // ARTICLE
            // =========================
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
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
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
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 55,
          color: Colors.grey,
        ),
      ),
    );
  }
}