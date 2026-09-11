import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'pages/home_page.dart';
import 'pages/add_post_page.dart';
import 'pages/category_page.dart';

void main() {
  runApp(const BlogApp());
}

class BlogApp extends StatelessWidget {
  const BlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blog App',
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AddPostPage(),
    CategoryPage(),
  ];

  final _items = [
    SalomonBottomBarItem(
      icon: const Icon(Icons.home_outlined),
      title: const Text("Home"),
      selectedColor: Colors.blue,
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.add),
      title: const Text("Tambah"),
      selectedColor: Colors.green,
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.category_outlined),
      title: const Text("Category"),
      selectedColor: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.menu_book_rounded),
        centerTitle: true,
      ),

      body: _pages[_currentIndex],

      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        items: _items,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}