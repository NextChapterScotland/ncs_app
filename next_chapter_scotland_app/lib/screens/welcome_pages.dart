import 'package:flutter/material.dart';
import 'signup.dart';

class WelcomePages extends StatefulWidget {
  const WelcomePages({super.key});

  @override
  State<WelcomePages> createState() => _WelcomePagesState();
}

class _WelcomePagesState extends State<WelcomePages> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SignupPage()));
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : null,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() {
                    _currentPage = index;
                  });
                }
              },
              children: [
                _buildPage(
                  gifAsset: 'assets/heart-beat-glitter.gif',
                  title: 'Support without judgment',
                  text:
                      'Next Chapter Scotland supports anyone in Scotland affected by the criminal justice system with non-judgemental, rights-based help.',
                ),
                _buildPage(
                  gifAsset: 'assets/community-talk.gif',
                  title: 'Information and community',
                  text:
                      'Find clear information, lived-experience insight and community to reduce isolation and build hope.',
                ),
                _buildPage(
                  gifAsset: 'assets/hammer.gif',
                  title: 'Defending your rights',
                  text:
                      'Challenge discrimination, understand your rights and imagine a fairer justice system together.',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEDD33),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _currentPage == _totalPages - 1 ? 'Go to Login' : 'Next',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String gifAsset,
    required String title,
    required String text,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(gifAsset, height: 220, fit: BoxFit.contain),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
