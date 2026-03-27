import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:push_notification_manager/push_notification_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:next_chapter_scotland_app/screens/login.dart';
import 'package:next_chapter_scotland_app/screens/signup.dart';
import 'package:next_chapter_scotland_app/screens/edit_profile_screen.dart';
import 'package:next_chapter_scotland_app/screens/change_password_screen.dart';
import 'package:next_chapter_scotland_app/screens/my_posts_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utilities/utility_functions.dart';
import 'navigation.dart';

class Profile extends StatefulWidget {
  final bool isGuest;
  const Profile({super.key, this.isGuest = false});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _supabase = Supabase.instance.client;
  bool? _notificationsEnabled;
  String? _username;
  String? _email;
  String? _bio;
  String? _profileColour;
  int _postCount = 0;
  int _totalLikes = 0;
  DateTime? _joinedAt;

  bool _loading = true;
  bool get _isGuest => widget.isGuest;

  @override
  void initState() {
    super.initState();
    if (_isGuest) {
      _username = 'Guest';
      _email = '';
      _bio = '';
      _loading = false;
    } else {
      _loadUsername();
      _loadUserStats();
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _loadUsername() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _username = 'Guest';
          _email = '';
          _bio = '';
          _loading = false;
        });
      }
      return;
    }

    final data = await _supabase
        .from('profiles')
        .select('username, bio, profile_colour, notifications_enabled')
        .eq('id', user.id)
        .single();

    if (mounted) {  
      setState(() {
        _username = data['username'] ?? user.email ?? 'User';
        _email = user.email;
        _bio = data['bio'] ?? '';
        _profileColour = data['profile_colour'];
        _notificationsEnabled = data['notifications_enabled'];
        _loading = false;
      });
    }
  }

  Future<void> _loadUserStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final stats = await _supabase.rpc(
      'get_user_stats',
      params: {'user_id': user.id},
    );

    final row = (stats as List).first;

    _totalLikes = await fetchUserLikes(_supabase, user.id);
    if (mounted) {
      setState(() {
        _postCount = row['post_count'] as int;
        _joinedAt = DateTime.parse(user.createdAt);
      });
    }
  }

  String _initialFromUsername(String? username) {
    final u = (username ?? '').trim();
    if (u.isEmpty) return 'G';
    return u[0].toUpperCase();
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

  Future<void> _onNotificationsChanged(bool value) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('profiles')
        .update({'notifications_enabled': value})
        .eq('id', userId ?? '');

    final pushManager = PushNotificationManager();

    if (value) {
      await pushManager.requestPermissionsIfNeeded();

      await pushManager.initNotifications(
        notificationsEnabled: true,
        onToken: (token) async {
          await _supabase.from('user_fcm_tokens').upsert({
            'user_id': userId,
            'fcm_token': token,
          }, onConflict: 'user_id, fcm_token');
        },
      );
    } else {
      await _removeFcmToken();
    }

    if (mounted) {
      setState(() {
        _notificationsEnabled = value;
      });
    }
  }

  Future<void> _removeFcmToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await PushNotificationManager().removeFcmToken(
      onRemove: (token) async {
        await _supabase
            .from('user_fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('fcm_token', token);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFEDD33),
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
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
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFEDD33),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: _loading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 28,
                              backgroundColor: _hexToColor(_profileColour),
                              child: Text(
                                _initialFromUsername(_username),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _loading ? '…' : (_username ?? ''),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _loading ? '…' : (_email ?? ''),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_bio != null && _bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Text(
                      _bio!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!_isGuest)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: "Posts", value: _postCount),
                  _StatItem(
                    label: "Likes",
                    value: _postCount > 0
                        ? (_totalLikes - 2).clamp(0, double.infinity).toInt()
                        : 0,
                  ),
                  _StatItem(
                    label: "Joined",
                    value: _joinedAt == null
                        ? "-"
                        : "${_joinedAt!.day}/${_joinedAt!.month}/${_joinedAt!.year}",
                  ),
                ],
              ),
            ),
          if (!_isGuest &&
              (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.android))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Text(
                    "Settings",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!_loading)
                  SwitchListTile(
                    title: const Text(
                      "Notifications",
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _notificationsEnabled ?? true,
                    onChanged: _onNotificationsChanged,
                    secondary: const Icon(Icons.notifications),
                  ),
                const Divider(),
              ],
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              "Other",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help & Support", style: TextStyle(fontSize: 14)),
            onTap: () =>
                _launchURL('https://www.nextchapterscotland.org.uk/contact'),
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism_outlined),
            title: const Text("Donate", style: TextStyle(fontSize: 14)),
            onTap: () =>
                _launchURL('https://www.nextchapterscotland.org.uk/donate'),
          ),
          if (_isGuest) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text(
                "Account",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text("Log In", style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text("Sign Up", style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                );
              },
            ),
          ],
          if (!_isGuest) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Account",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text("My posts", style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyPostsScreen(
                      userId: _supabase.auth.currentUser!.id,
                      username: _username ?? 'User',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit profile", style: TextStyle(fontSize: 14)),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      userId: _supabase.auth.currentUser!.id,
                      currentUsername: _username ?? '',
                      currentBio: _bio ?? '',
                      currentProfileColour: _profileColour,
                    ),
                  ),
                );

                if (result == true && mounted) {
                  if (mounted) {
                    setState(() {
                      _loading = true;
                    });
                  }
                  await _loadUsername();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text(
                "Change password",
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Log out",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              onTap: () async {
                await _removeFcmToken();
                await _supabase.auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const Navigation(isGuest: true),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final dynamic value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
