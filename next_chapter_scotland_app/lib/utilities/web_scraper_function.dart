import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class InfoHubTopic {
  final String name;
  final String url;
  InfoHubTopic({required this.name, required this.url});
}

class InfoHubContentBlock {
  final String? heading;
  final String? body;
  final List<InfoHubLink> links;
  InfoHubContentBlock({this.heading, this.body, this.links = const []});
}

class InfoHubLink {
  final String text;
  final String url;
  InfoHubLink({required this.text, required this.url});
}

Future<List<InfoHubTopic>> fetchTopics(String categoryUrl) async {
  try {
    final data = await _supabase
        .from('info_hub_topics')
        .select('name, url')
        .eq('category_url', categoryUrl);

    return (data as List)
        .map(
          (row) => InfoHubTopic(
            name: row['name'] as String,
            url: row['url'] as String,
          ),
        )
        .toList();
  } catch (_) {
    return [];
  }
}

Future<List<InfoHubContentBlock>> fetchTopicContent(String topicUrl) async {
  try {
    final data = await _supabase
        .from('info_hub_content')
        .select('heading, body, links')
        .eq('topic_url', topicUrl);

    return (data as List).map((row) {
      final rawLinks = (row['links'] as List? ?? []);
      final links = rawLinks
          .map(
            (l) =>
                InfoHubLink(text: l['text'] as String, url: l['url'] as String),
          )
          .toList();

      return InfoHubContentBlock(
        heading: row['heading'] as String?,
        body: row['body'] as String?,
        links: links,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}
