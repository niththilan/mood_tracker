import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/google_auth_service.dart';
import '../services/supabase_config.dart';

/// iOS Google Sign-In Diagnostic Widget
class IOSGoogleSignInDiagnostic extends StatefulWidget {
  const IOSGoogleSignInDiagnostic({super.key});

  @override
  _IOSGoogleSignInDiagnosticState createState() => _IOSGoogleSignInDiagnosticState();
}

class _IOSGoogleSignInDiagnosticState extends State<IOSGoogleSignInDiagnostic> {
  final List<String> _diagnosticResults = [];
  bool _isRunning = false;

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _diagnosticResults.clear();
    });

    _addResult('🔍 Starting iOS Google Sign-In Diagnostics...');
    
    // Check platform
    if (kIsWeb) {
      _addResult('❌ Running on Web - iOS diagnostics not applicable');
      setState(() => _isRunning = false);
      return;
    }

    try {
      if (!Platform.isIOS) {
        _addResult('❌ Not running on iOS - diagnostics not applicable');
        setState(() => _isRunning = false);
        return;
      }

      _addResult('✅ Platform: iOS detected');
      
      // Check configuration
      _addResult('📋 Checking configuration...');
      _addResult('   • iOS Client ID: ${SupabaseConfig.googleIOSClientId}');
      
      if (SupabaseConfig.googleIOSClientId.isEmpty) {
        _addResult('❌ iOS Client ID is empty!');
      } else {
        _addResult('✅ iOS Client ID configured');
      }
      
      // Test Google Sign-In service
      _addResult('🔧 Testing Google Sign-In service...');
      final configTest = await GoogleAuthService.testIOSConfiguration();
      
      if (configTest) {
        _addResult('✅ iOS Google Sign-In configuration test passed');
      } else {
        _addResult('❌ iOS Google Sign-In configuration test failed');
      }
      
      // Check sign-in status
      final isSignedIn = await GoogleAuthService.isSignedIn();
      _addResult('👤 Current sign-in status: ${isSignedIn ? "Signed In" : "Not Signed In"}');
      
      if (isSignedIn) {
        // Note: getCurrentUser is not available in simplified Supabase-only auth
        _addResult('   • Using Supabase authentication');
        _addResult('   • Check Supabase client for user details');
      }
      
      _addResult('✅ Diagnostics completed successfully');
      
    } catch (error) {
      _addResult('❌ Diagnostic error: $error');
    }
    
    setState(() => _isRunning = false);
  }

  void _addResult(String result) {
    setState(() {
      _diagnosticResults.add(result);
    });
  }

  Future<void> _testSignIn() async {
    _addResult('🧪 Testing Google Sign-In...');
    
    try {
      final response = await GoogleAuthService.signInWithGoogle();
      if (response != null) {
        _addResult('✅ Sign-in test successful');
        _addResult('   • User: ${response.user?.email ?? "Unknown"}');
      } else {
        _addResult('⚠️ Sign-in returned null (may have been cancelled)');
      }
    } catch (error) {
      _addResult('❌ Sign-in test failed: $error');
    }
  }

  Future<void> _testSignOut() async {
    _addResult('🔐 Testing Sign-Out...');
    
    try {
      await GoogleAuthService.signOut();
      _addResult('✅ Sign-out successful');
    } catch (error) {
      _addResult('❌ Sign-out failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('iOS Google Sign-In Diagnostics'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'iOS Google Sign-In Diagnostic Tool',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _runDiagnostics,
                  child: Text(_isRunning ? 'Running...' : 'Run Diagnostics'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isRunning ? null : _testSignIn,
                  child: Text('Test Sign-In'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isRunning ? null : _testSignOut,
                  child: Text('Test Sign-Out'),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Text(
              'Results:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            
            SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _diagnosticResults.isEmpty 
                        ? 'No diagnostics run yet. Click "Run Diagnostics" to start.'
                        : _diagnosticResults.join('\n'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Common iOS Google Sign-In Issues:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Invalid or missing GoogleService-Info.plist'),
                  Text('• Incorrect URL schemes in Info.plist'),
                  Text('• Missing client ID configuration'),
                  Text('• Keychain access issues'),
                  Text('• Network connectivity problems'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
