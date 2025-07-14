import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../services/google_auth_service.dart';
import '../services/supabase_config.dart';

class GoogleAuthDebugWidget extends StatefulWidget {
  @override
  _GoogleAuthDebugWidgetState createState() => _GoogleAuthDebugWidgetState();
}

class _GoogleAuthDebugWidgetState extends State<GoogleAuthDebugWidget> {
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  void _loadDebugInfo() {
    setState(() {
      _debugInfo = '''
Platform Info:
- Is Web: ${kIsWeb}
- Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}
- Is Debug Mode: ${kDebugMode}

Google OAuth Configuration:
- iOS Client ID: ${SupabaseConfig.googleIOSClientId}
- Android Client ID: ${SupabaseConfig.googleAndroidClientId}
- Web Client ID: ${SupabaseConfig.googleWebClientId}

Supabase Configuration:
- URL: ${SupabaseConfig.supabaseUrl}
- Callback URL: ${SupabaseConfig.oauthCallbackUrl}
''';
    });
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _debugInfo += '\n--- Testing Google Sign-In ---\n';
    });

    try {
      setState(() {
        _debugInfo += 'Initializing Google Auth Service...\n';
      });

      await GoogleAuthService.initialize();

      setState(() {
        _debugInfo += 'Google Auth Service initialized successfully\n';
        _debugInfo += 'Starting sign-in process...\n';
      });

      final response = await GoogleAuthService.signInWithGoogle();

      if (response != null) {
        setState(() {
          _debugInfo += 'Sign-in successful!\n';
          _debugInfo += 'User: ${response.user?.email}\n';
        });
      } else {
        setState(() {
          _debugInfo += 'Sign-in cancelled by user\n';
        });
      }
    } catch (error) {
      setState(() {
        _debugInfo += 'Sign-in error: $error\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Auth Debug')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testGoogleSignIn,
              child:
                  _isLoading
                      ? CircularProgressIndicator()
                      : Text('Test Google Sign-In'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
