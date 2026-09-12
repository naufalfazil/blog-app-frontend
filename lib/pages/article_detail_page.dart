import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'edit_post_page.dart';

class ArticleDetailPage extends StatelessWidget {
  final Map article;

  const ArticleDetailPage({
    super.key,
    required this.article,
  });


  Future<void> _deletePost(BuildContext context) async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus Artikel?',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        content: const Text(
          'Artikel ini akan dihapus. Apakah kamu yakin?',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            style: TextButton.styleFrom(
              foregroundColor: Color.fromARGB(255, 157, 98, 40),
              side: const BorderSide(
                color: Color.fromARGB(255, 157, 98, 40),
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 157, 98, 40),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirm != true) return;

  try {
    final int id = article['id'];

    final response = await http.delete(
      Uri.parse(
        'http://localhost:3000/api/v1/posts/$id',
      ),
    );

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil dihapus'),
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus artikel (${response.statusCode})',
          ),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terjadi kesalahan saat menghapus artikel'),
      ),
    );

    debugPrint('Error delete post: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar full width + tombol back di dalam gambar
            Stack(
              children: [
                article['imageUrl'] != null &&
                        article['imageUrl'].toString().isNotEmpty
                    ? Image.network(
                        article['imageUrl'].toString(),
                        width: double.infinity,
                        height: 420,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _imagePlaceholder();
                        },
                      )
                    : _imagePlaceholder(),

                // Tombol back
                Positioned(
                  top: 45,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Bagian judul dan content tetap diberi padding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    article['title'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Content
                  Text(
                    article['content'] ?? 'Tidak ada isi artikel.',
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Color.fromARGB(255, 157, 98, 40),
                          child: IconButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPostPage(
                                    article: article,
                                  ),
                                ),
                              );
                        
                              if (result == true && context.mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                            icon: const Icon(Icons.edit_rounded),
                            color: const Color.fromARGB(255, 255, 255, 255),
                            tooltip: 'Edit',
                          ),
                        ),
                      ),

                      CircleAvatar(
                        backgroundColor:  Color.fromARGB(255, 157, 98, 40),
                        child: IconButton(
                          onPressed: () {
                            _deletePost(context);
                          },
                          icon: const Icon(Icons.delete_rounded),
                          color:  Color.fromARGB(255, 255, 255, 255),
                          tooltip: 'Hapus',
                        ),
                      ),
                    ],
                  ),
                ],
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
      height: 320,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 60,
          color: Colors.grey,
        ),
      ),
    );
  }
}