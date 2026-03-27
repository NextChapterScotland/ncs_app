import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'navigation.dart';
import 'login.dart';

class UsernameScreen extends StatefulWidget {
  final String userId;
  final String email;

  const UsernameScreen({super.key, required this.userId, required this.email});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _usernameController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _isSaving = false;
  bool _isChecking = false;
  bool _isUsernameAvailable = false;
  String? _errorMessage;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _checkUsername);
  }

  Future<void> _checkUsername() async {
    final raw = _usernameController.text.trim();
    final username = raw.toLowerCase();

    if (raw.isEmpty) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isUsernameAvailable = false;
          _errorMessage = null;
        });
      }
      return;
    }

    if (raw.length < 3) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isUsernameAvailable = false;
          _errorMessage = 'Username must be at least 3 characters';
        });
      }
      return;
    }

    if (raw.length > 20) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isUsernameAvailable = false;
          _errorMessage = 'Username must be less than 20 characters';
        });
      }
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(raw)) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isUsernameAvailable = false;
          _errorMessage = 'Only letters, numbers, and underscores allowed';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isChecking = true;
        _isUsernameAvailable = false;
        _errorMessage = null;
      });
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isChecking = false;
          if (response == null) {
            _isUsernameAvailable = true;
            _errorMessage = null;
          } else {
            _isUsernameAvailable = false;
            _errorMessage = 'This username is already taken';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isUsernameAvailable = false;
          _errorMessage = 'Error checking username. Please try again.';
        });
      }
    }
  }

  Future<void> _saveUsername() async {
    final raw = _usernameController.text.trim();
    final username = raw.toLowerCase();

    if (!_isUsernameAvailable || raw.isEmpty) return;

    if (mounted) {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });
    }

    try {
      await _supabase.from('profiles').upsert({
        'id': widget.userId,
        'username': username,
        'email': widget.email,
      });

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Navigation(isGuest: false)),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save username. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final input = _usernameController.text.trim();
    final canContinue = _isUsernameAvailable && !_isSaving;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/next_chapter_logo.png', height: 80),
                const SizedBox(height: 32),
                const Text(
                  'Choose a username',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Color(0xFF1C1C1C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  "Keep it anonymous — don't use your real name.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                    color: Color(0xFF1C1C1C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For your safety, DO NOT use identifying information.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isUsernameAvailable && input.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '"$input" is available!',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _usernameController,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    suffixIcon: input.isEmpty
                        ? const Icon(Icons.person_outline)
                        : _isChecking
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(
                            _isUsernameAvailable
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _isUsernameAvailable
                                ? Colors.green
                                : Colors.red,
                          ),
                    helperText:
                        '3–20 chars • letters, numbers, underscore\nKeep it respectful',
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: canContinue ? _saveUsername : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEDD33),
                      disabledBackgroundColor: const Color(0xFFF3F3F3),
                      disabledForegroundColor: const Color(0xFFB0B0B0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This username will be shown on posts and comments.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
