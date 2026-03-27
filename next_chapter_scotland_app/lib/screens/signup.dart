import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'navigation.dart';
import 'login.dart';
import 'username_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupState();
}

class _SignupState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  SupabaseClient get _supabase => Supabase.instance.client;

  String? _errorMessage;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEmailValid = false;
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
  bool _isSignupEnabled = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String value) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
  }

  void _onEmailChanged(String value) {
    _isEmailValid = _validateEmail(value.trim());
    _updateSignupState();
  }

  void _onPasswordChanged(String value) {
    _hasMinLength = value.length >= 8;
    _hasNumber = value.contains(RegExp(r'\d'));
    _hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    _updateSignupState();
  }

  void _updateSignupState() {
    if (mounted) {
      setState(() {
        _isSignupEnabled = _isEmailValid && _hasMinLength && _hasNumber && _hasSpecial;
      });
    }
  }

  Future<void> _signUp() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authResponse = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'nextchapter://login-callback',
      );

      if (authResponse.user != null && mounted) {
        if (authResponse.session == null) {
          if (mounted) {
            setState(() {
              _errorMessage = null;
              _isLoading = false;
            });
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Check your email!'),
              content: const Text(
                'We sent a confirmation link to your email. Once confirmed, come back and log in.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => UsernameScreen(
                userId: authResponse.user!.id,
                email: _emailController.text.trim(),
              ),
            ),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      // Better error messages for users
      String userMessage;
      if (e.message.contains('invalid')) {
        userMessage = 'Please use a valid email address.';
      } else if (e.message.contains('already registered')) {
        userMessage =
            'This email is already registered. Please log in instead.';
      } else if (e.message.contains('password')) {
        userMessage = 'Password issue. Please try a different one.';
      } else {
        userMessage = 'Unable to sign up. Please try again.';
      }
      if (mounted) {
        setState(() {
          _errorMessage = userMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/next_chapter_logo.png', height: 80),
                const SizedBox(height: 32),
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign Up to continue',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.normal,
                    fontSize: 18,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16, top: 16),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _onEmailChanged,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(
                      _isEmailValid ? Icons.check_circle : Icons.email,
                      color: _isEmailValid ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  onChanged: _onPasswordChanged,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        }
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PasswordRuleItem(
                      text: 'At least 8 characters',
                      satisfied: _hasMinLength,
                    ),
                    _PasswordRuleItem(
                      text: 'Contains a number',
                      satisfied: _hasNumber,
                    ),
                    _PasswordRuleItem(
                      text: 'Contains a special character (!, @, #, ...)',
                      satisfied: _hasSpecial,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: _isSignupEnabled && !_isLoading ? _signUp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEDD33),
                      disabledBackgroundColor: const Color(0xFFF3F3F3),
                      disabledForegroundColor: const Color(0xFFB0B0B0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => Navigation(isGuest: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEDD33),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continue as guest',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRuleItem extends StatelessWidget {
  final String text;
  final bool satisfied;

  const _PasswordRuleItem({required this.text, required this.satisfied});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: satisfied ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: satisfied ? Colors.green : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
