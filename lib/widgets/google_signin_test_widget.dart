import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/google_auth_service.dart';
import '../services/supabase_config.dart';

class GoogleSignInTestWidget extends StatefulWidget {
  @override
  _GoogleSignInTestWidgetState createState() => _GoogleSignInTestWidgetState();
}

class _GoogleSignInTestWidgetState extends State<GoogleSignInTestWidget> {
  String _status = 'Ready to test Google Sign-In';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Sign-In Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Text(
              'Configuration:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text('Package: com.example.mood_tracker'),
            Text('Android Client ID: ${SupabaseConfig.googleAndroidClientId}'),
            Text('Web Client ID: ${SupabaseConfig.googleWebClientId}'),
            SizedBox(height: 16),
            Text('Status:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testGoogleSignIn,
                    child:
                        _isLoading
                            ? CircularProgressIndicator(strokeWidth: 2)
                            : Text('Test Google Sign-In'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testInitialization,
                    child: Text('Test Initialization'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testInitialization() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Google Sign-In initialization...';
    });

    try {
      await GoogleAuthService.initialize();
      setState(() {
        _status = 'Google Sign-In initialized successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Google Sign-In...';
    });

    try {
      if (kDebugMode) {
        print('Starting Google Sign-In test...');
      }

      final response = await GoogleAuthService.signInWithGoogle();

      if (response == null) {
        setState(() {
          _status = 'Sign-in was cancelled by user';
        });
      } else {
        setState(() {
          _status =
              'Sign-in successful!\n'
              'User: ${response.user?.email}\n'
              'Provider: ${response.user?.appMetadata['provider']}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Sign-in failed: $e';
      });

      if (kDebugMode) {
        print('Google Sign-In test failed: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
