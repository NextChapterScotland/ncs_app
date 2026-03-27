import 'package:flutter/material.dart';
import 'dart:io';
import '../utilities/web_scraper_function.dart';
import 'topic_page.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;
  final String categoryUrl;
  final Color color;

  const CategoryPage({
    super.key,
    required this.categoryName,
    required this.categoryUrl,
    required this.color,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late Future<List<InfoHubTopic>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicsFuture = fetchTopics(widget.categoryUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.color,
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              iconSize: 28,
              icon: const Icon(Icons.exit_to_app, color: Color(0xFFCC3300)),
              tooltip: 'Quick Exit',
              onPressed: () => exit(0),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<InfoHubTopic>>(
        future: _topicsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No topics found.'));
          }

          final topics = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final topic = topics[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicPage(
                      topicName: topic.name,
                      topicUrl: topic.url,
                      color: widget.color,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEDD33),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    topic.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
