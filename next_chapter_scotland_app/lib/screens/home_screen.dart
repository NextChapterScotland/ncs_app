import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_chapter_scotland_app/screens/topic_page.dart';
import 'package:push_notification_manager/push_notification_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'training_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'category_page.dart';

class HomePage extends StatefulWidget {
  final bool isGuest;
  const HomePage({super.key, this.isGuest = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  String? _username;
  String? _profileColour;
  bool? _notificationsEnabled;
  bool _loading = true;
  bool _isGuest = false;
  String _searchQuery = '';
  Timer? _searchDebounce;
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  final Map<String, Color> _categoryColours = {
    'https://www.nextchapterscotland.org.uk/work': Color(0xFFD7C7FF),
    'https://www.nextchapterscotland.org.uk/family-and-society': Color(
      0xFFFFC7CD,
    ),
    'https://www.nextchapterscotland.org.uk/health': Color(0xFFC5F5CF),
    'https://www.nextchapterscotland.org.uk/living-life': Color(0xFFC7F0FF),
    'https://www.nextchapterscotland.org.uk/money-matters': Color(0xFFFFDFB2),
    'https://www.nextchapterscotland.org.uk/criminal-justice-system': Color(
      0xFFC9D0FF,
    ),
    'https://www.nextchapterscotland.org.uk/housing': Color(0xFFB2EDCC),
    'https://www.nextchapterscotland.org.uk/defending-your-rights': Color(
      0xFFFFD6B2,
    ),
    'https://www.nextchapterscotland.org.uk/for-professionals': Color(
      0xFFE2A9F1,
    ),
  };

  @override
  void initState() {
    super.initState();
    _isGuest = widget.isGuest;
    if (_isGuest) {
      _username = 'Guest';
      _loading = false;
    } else {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await _loadUsername();
    if (!mounted) return;
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final pushManager = PushNotificationManager();

    await pushManager.initNotifications(
      notificationsEnabled: _notificationsEnabled ?? false,
      onToken: (token) async {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          await _supabase.from('user_fcm_tokens').upsert({
            'user_id': userId,
            'fcm_token': token,
          }, onConflict: 'user_id, fcm_token');
        }
      },
    );
  }

  Future<void> _performSearch(String value) async {
    if (mounted) setState(() => _isSearching = true);

    final content = await _supabase
        .from('info_hub_content')
        .select('heading, body, topic_url')
        .ilike('body', '%$value%');

    final topicUrls = content
        .map((item) => item['topic_url'] as String)
        .toSet()
        .toList();

    if (topicUrls.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    final topics = await _supabase
        .from('info_hub_topics')
        .select('name, url, category_url')
        .inFilter('url', topicUrls);

    final topicsMap = {for (var t in topics) t['url']: t};

    final List<SearchResult> mapped = content.map((item) {
      final body = item['body'] as String;
      final topic = topicsMap[item['topic_url']];

      final int index = body.toLowerCase().indexOf(value.toLowerCase());
      final start = (index - 40).clamp(0, body.length);
      final end = (index + 40).clamp(0, body.length);
      final snippet = body.substring(start, end);

      return SearchResult(
        topicName: topic?['name'] ?? '',
        topicUrl: item['topic_url'],
        heading: item['heading'] ?? 'No heading',
        snippet: snippet,
        categoryUrl: topic?['category_url'] ?? '',
      );
    }).toList();

    if (mounted) {
      setState(() {
        _searchResults = mapped;
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      if (_searchQuery.isEmpty) {
        if (mounted) {
          setState(() {
            _searchResults = [];
          });
        }
      } else {
        _performSearch(value);
      }
    });
  }

  Future<void> _loadUsername() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _username = 'Guest';
          _loading = false;
        });
      }
      return;
    }

    final data = await _supabase
        .from('profiles')
        .select('username, profile_colour, notifications_enabled')
        .eq('id', user.id)
        .single();

    if (mounted) {
      setState(() {
        _username = data['username'] ?? user.email ?? 'User';
        _profileColour = data['profile_colour'];
        _notificationsEnabled = data['notifications_enabled'];
        _loading = false;
      });
    }
  }

  Future<void> _launchWebsite() async {
    final uri = Uri.parse('https://www.nextchapterscotland.org.uk/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open website')));
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) {
      return const Color(0xFFFEDD33);
    }

    final cleanedHex = hex
        .trim()
        .replaceAll('#', '')
        .replaceAll("'", '')
        .replaceAll('"', '');

    try {
      return Color(int.parse('FF$cleanedHex', radix: 16));
    } catch (_) {
      return const Color(0xFFFEDD33);
    }
  }

  @override
  void dispose() {
    PushNotificationManager().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loading ? 'Hi…' : 'Hi, $_username',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Welcome back!',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _loading
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : CircleAvatar(
                          radius: 24,
                          backgroundColor: _hexToColor(_profileColour),
                          child: Text(
                            ((_username ?? 'G').trim().isNotEmpty
                                    ? (_username ?? 'G').trim()[0]
                                    : 'G')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Color(0xFFCC3300),
                    ),
                    tooltip: 'Quick Exit',
                    onPressed: () => exit(0),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                child: Center(
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      icon: Icon(Icons.search),
                      hintText: 'Search topics, support, or guides...',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _searchResults.isEmpty && _searchQuery.isEmpty
                    ? Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _launchWebsite,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFFEDD33),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    color: Colors.black.withValues(alpha: 0.04),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: const [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Color(0xFFFEDD33),
                                    child: Icon(
                                      Icons.language,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Next Chapter Scotland Website',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Visit the official website',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Explore topics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 3 / 2.6,
                              children: [
                                _CategoryCard(
                                  title: 'Work',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/work']!,
                                  icon: Icons.work_outline,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryPage(
                                          categoryName: 'Work',
                                          categoryUrl:
                                              'https://www.nextchapterscotland.org.uk/work',
                                          color:
                                              _categoryColours['https://www.nextchapterscotland.org.uk/work']!,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _CategoryCard(
                                  title: 'Family & Society',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/family-and-society']!,
                                  icon: Icons.groups_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        categoryName: 'Family & Society',
                                        categoryUrl:
                                            'https://www.nextchapterscotland.org.uk/family-and-society',
                                        color:
                                            _categoryColours['https://www.nextchapterscotland.org.uk/family-and-society']!,
                                      ),
                                    ),
                                  ),
                                ),
                                _CategoryCard(
                                  title: 'Health',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/health']!,
                                  icon: Icons.health_and_safety_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        categoryName: 'Health',
                                        categoryUrl:
                                            'https://www.nextchapterscotland.org.uk/health',
                                        color:
                                            _categoryColours['https://www.nextchapterscotland.org.uk/health']!,
                                      ),
                                    ),
                                  ),
                                ),
                                _CategoryCard(
                                  title: 'Living Life',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/living-life']!,
                                  icon: Icons.auto_awesome,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        categoryName: 'Living Life',
                                        categoryUrl:
                                            'https://www.nextchapterscotland.org.uk/living-life',
                                        color:
                                            _categoryColours['https://www.nextchapterscotland.org.uk/living-life']!,
                                      ),
                                    ),
                                  ),
                                ),
                                _CategoryCard(
                                  title: 'Money Matters',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/money-matters']!,
                                  icon: Icons.attach_money,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        categoryName: 'Money Matters',
                                        categoryUrl:
                                            'https://www.nextchapterscotland.org.uk/money-matters',
                                        color:
                                            _categoryColours['https://www.nextchapterscotland.org.uk/money-matters']!,
                                      ),
                                    ),
                                  ),
                                ),
                                _CategoryCard(
                                  title: 'Criminal Justice System',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/criminal-justice-system']!,
                                  icon: Icons.gavel_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        categoryName: 'Criminal Justice System',
                                        categoryUrl:
                                            'https://www.nextchapterscotland.org.uk/criminal-justice-system',
                                        color:
                                            _categoryColours['https://www.nextchapterscotland.org.uk/criminal-justice-system']!,
                                      ),
                                    ),
                                  ),
                                ),
                                _CategoryCard(
                                  title: 'Housing',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/housing']!,
                                  icon: Icons.home_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        categoryName: 'Housing',
                                        categoryUrl:
                                            'https://www.nextchapterscotland.org.uk/housing',
                                        color:
                                            _categoryColours['https://www.nextchapterscotland.org.uk/housing']!,
                                      ),
                                    ),
                                  ),
                                ),
                                _CategoryCard(
                                  title: 'Defending Your Rights',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/defending-your-rights']!,
                                  icon: Icons.security_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        categoryName: 'Defending Your Rights',
                                        categoryUrl:
                                            'https://www.nextchapterscotland.org.uk/defending-your-rights',
                                        color:
                                            _categoryColours['https://www.nextchapterscotland.org.uk/defending-your-rights']!,
                                      ),
                                    ),
                                  ),
                                ),
                                _CategoryCard(
                                  title: 'For Professionals',
                                  color:
                                      _categoryColours['https://www.nextchapterscotland.org.uk/for-professionals']!,
                                  icon: Icons.badge,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(
                                        categoryName: 'For Professionals',
                                        categoryUrl:
                                            'https://www.nextchapterscotland.org.uk/for-professionals',
                                        color:
                                            _categoryColours['https://www.nextchapterscotland.org.uk/for-professionals']!,
                                      ),
                                    ),
                                  ),
                                ),
                                _CategoryCard(
                                  title: 'Training',
                                  color: const Color(0xFF9FD6CF),
                                  icon: Icons.school,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TrainingScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty && _searchQuery.isNotEmpty
                    ? const Center(child: Text('No results found'))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TopicPage(
                                        topicName: result.topicName,
                                        topicUrl: result.topicUrl,
                                        color:
                                            _categoryColours[result
                                                .categoryUrl]!,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result.topicName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '...${result.snippet}...',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 4),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResult {
  final String topicName;
  final String topicUrl;
  final String heading;
  final String snippet;
  final String categoryUrl;

  SearchResult({
    required this.topicName,
    required this.topicUrl,
    required this.heading,
    required this.snippet,
    required this.categoryUrl,
  });
}
