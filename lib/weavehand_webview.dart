import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data'; // <-- Added for Uint8List
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  var _loadingPercentage = 0;
  bool _pageLoaded = false;

  // --- 1. CREATE A GoogleSignIn INSTANCE ---
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();

    // --- 2. INITIALIZE GoogleSignIn WITH YOUR SERVER CLIENT ID ---
    _googleSignIn.initialize(
      // This is the "Web client ID" from your Google Cloud Console.
      serverClientId: '806715633821-j78fqg0qokd3cpfuu7972p1u7fpkp3qv.apps.googleusercontent.com',
    );
    // --- END OF FIX ---

    _controller = WebViewController()
      ..setBackgroundColor(const Color(0x00000000))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'GoogleLogin', // This is here just in case, but we won't use it
        onMessageReceived: (JavaScriptMessage message) {
          _handleGoogleLogin();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _loadingPercentage = 0;
              _pageLoaded = false;
            });
          },
          onProgress: (progress) {
            setState(() {
              _loadingPercentage = progress;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _loadingPercentage = 100;
              _pageLoaded = true;
            });
          },
          onWebResourceError: (error) {
            if (_pageLoaded && !error.description.contains('Blocked by client')) {
              debugPrint('--- WebView Error: ${error.description} ---');
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.parse(request.url);

            // --- THIS CATCHES THE LOGIN CLICK ---
            if (request.url.startsWith('https://accounts.google.com') ||
                request.url.contains('google.com/o/oauth2')) {
              debugPrint("--- Google Login attempt detected, stopping WebView. ---");
              _handleGoogleLogin(); // Triggers our new function
              return NavigationDecision.prevent;
            }
            // --- END OF CATCH ---

            if (request.url.startsWith('https://api.whatsapp.com')) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                debugPrint('Could not launch WhatsApp.');
              }
              return NavigationDecision.prevent;
            } else if (uri.scheme == 'tel' || uri.scheme == 'mailto') {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.weavehand.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
        EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.04),
        child: WillPopScope(
          onWillPop: () async {
            if (await _controller.canGoBack()) {
              _controller.goBack();
              return false;
            }
            return true;
          },
          child: RefreshIndicator(
            onRefresh: () => _controller.reload(),
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loadingPercentage < 100)
                  Center(
                    child: CircularProgressIndicator(
                      value: _loadingPercentage / 100.0,
                      color: Color(0xFFEC1161),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- THIS IS YOUR LATEST FUNCTION ---
  Future<void> _handleGoogleLogin() async {
    debugPrint('--- Starting Google Sign-In... ---');

    try {
      // 1. & 2. Get the Google User
      // (This part is the same)
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        debugPrint('--- Google Sign-in canceled by user. ---');
        return;
      }

      // 3. Get the idToken
      // (This part is the same)
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('--- FAILED TO GET GOOGLE TOKEN: idToken is null. ---');
        return;
      }

      // --- 4. THIS IS THE NEW LOGIC ---
      // We are no longer using http.post.
      // We are telling the WebView to make the POST request.
      debugPrint('--- Google token acquired, sending to backend via WebView POST... ---');

      final url =
      Uri.parse('https://www.weavehand.com/collections/verify-app-token');

      // The WebView will POST the token to your PHP script.
      // The PHP script will run, set the cookie, and then
      // redirect the WebView to the homepage.
      await _controller.loadRequest(
        url,
        method: LoadRequestMethod.post,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: Uint8List.fromList(utf8.encode(jsonEncode({'idToken': idToken}))),
      );

      // We no longer need to check the response. The WebView
      // will handle the cookie and the redirect automatically.

    } catch (error) {
      debugPrint('--- GOOGLE SIGN-IN CATCH ERROR: $error ---');
    }
  }
}