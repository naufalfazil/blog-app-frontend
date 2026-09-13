import 'package:flutter/material.dart';
import 'package:frontend/pages/create_post_page.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'pages/home_page.dart';
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
    CategoryPage(),
  ];

  final _items = [
    SalomonBottomBarItem(
      icon: const Icon(Icons.home_outlined, color: Color.fromARGB(255, 157, 98, 40),),
      title: const Text("Home"),
      selectedColor:  Color.fromARGB(255, 157, 98, 40),
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.add, color: Color.fromARGB(255, 157, 98, 40),),
      title: const Text("Tambah"),
      selectedColor:  Color.fromARGB(255, 157, 98, 40),
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.dashboard_customize, color: Color.fromARGB(255, 157, 98, 40),),
      title: const Text("Category"),
      selectedColor:  Color.fromARGB(255, 157, 98, 40),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: _currentIndex == 2
      ? null
      : AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/BlogId.png',
                height: 40,
              ),
              const Text(
                'Blog',
                style: TextStyle(
                  fontFamily: 'Comic Relief',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Id',
                style: TextStyle(
                  fontFamily: 'Comic Relief',
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),

  body: _currentIndex == 0
      ? const HomePage()
      : _currentIndex == 2
          ? CategoryPage(
              onBack: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
            )
          : const SizedBox(),

  bottomNavigationBar: Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 400,
          child: SalomonBottomBar(
            currentIndex: _currentIndex,
            items: _items,
            onTap: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CreatePostPage(),
                  ),
                );
                return;
              }

              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ],
    ),
  ),
);
  }
}