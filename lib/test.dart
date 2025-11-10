// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// class WebViewScreen extends StatefulWidget {
//   const WebViewScreen({super.key});
//
//   @override
//   State<WebViewScreen> createState() => _WebViewScreenState();
// }
//
// class _WebViewScreenState extends State<WebViewScreen> {
//   late final WebViewController _controller;
//   var _loadingPercentage = 0;
//   bool _pageLoaded = false;
//
//   final String _webClientId = "806715633821-j78fqg0qokd3cpfuu7972p1u7fpkp3qv.apps.googleusercontent.com";
//   final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
//
//
//   @override
//   void initState() {
//     super.initState();
//
//     unawaited(
//       _googleSignIn.initialize(
//         serverClientId: _webClientId,
//       ),
//     );
//
//     _controller = WebViewController()
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (url) {
//             setState(() {
//               _loadingPercentage = 0;
//               _pageLoaded = false;
//             });
//             print('WebView loading: $url');
//           },
//           onProgress: (progress) {
//             setState(() {
//               _loadingPercentage = progress;
//             });
//           },
//           onPageFinished: (url) {
//             setState(() {
//               _loadingPercentage = 100;
//               _pageLoaded = true;
//             });
//           },
//           onWebResourceError: (error) {
//             print('WebView Error: ${error.description}');
//             if (_pageLoaded && !error.description.contains('Blocked by client')) {}
//           },
//           onNavigationRequest: (NavigationRequest request) async {
//             final uri = Uri.parse(request.url);
//
//             // Your WhatsApp logic (unchanged)
//             if (request.url.startsWith('https://api.whatsapp.com')) {
//               if (await canLaunchUrl(uri)) {
//                 await launchUrl(uri, mode: LaunchMode.externalApplication);
//               }
//               return NavigationDecision.prevent;
//             }
//             // Your tel/mailto logic (unchanged)
//             else if (uri.scheme == 'tel' || uri.scheme == 'mailto') {
//               if (await canLaunchUrl(uri)) {
//                 await launchUrl(uri);
//               }
//               return NavigationDecision.prevent;
//             }
//             // *** MODIFIED: Hybrid Google Sign-In logic ***
//             else if (request.url.startsWith('https://accounts.google.com/')) {
//
//               print('Google Sign-In URL intercepted. Calling NATIVE sign-in...');
//
//               // Call your native sign-in function
//               _handleNativeGoogleSignIn();
//
//               // Prevent the WebView from navigating
//               return NavigationDecision.prevent;
//             }
//
//             return NavigationDecision.navigate;
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse('https://www.weavehand.com/'));
//   }
//
//
//   // *** THIS FUNCTION IS NOW FIXED ***
//   Future<void> _handleNativeGoogleSignIn() async {
//
//     try {
//       // *** 1. MODIFIED: Called authenticate() instead of signIn() ***
//       // This throws an exception if the user cancels.
//       final GoogleSignInAccount account = await _googleSignIn.authenticate();
//
//       // *** 2. REMOVED: The (account == null) check is no longer needed. ***
//
//       // 3. Get the authentication token
//       final GoogleSignInAuthentication auth = await account.authentication;
//       final String? idToken = auth.idToken; // This is the magic token
//
//       print('Google Sign-In success. Got idToken. $idToken');
//
//       if (idToken != null) {
//         // 4. Pass the token to your WebView
//         // Your web developer MUST create a JavaScript function
//         // on the website called 'handleNativeLogin'
//
//         // Escape the token string for JavaScript
//         final String escapedToken = idToken.replaceAll("'", "\\'");
//         _controller.runJavaScript("handleNativeLogin('$escapedToken');");
//         print('Token passed to WebView.');
//       } else {
//         // This is a valid check, idToken *can* be null
//         print('Google Sign-In Error: idToken was null.');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Google Sign-In failed: No token received.')),
//           );
//         }
//       }
//     } catch (error) {
//       // *** 5. ADDED: Specific handling for user cancellation ***
//       if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled) {
//         // User cancelled the sign-in
//         print('Google Sign-In cancelled by user.');
//       } else {
//         // Other error
//         print("Google Sign-In Error: $error");
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Google Sign-In failed.')),
//           );
//         }
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // ... (Your build method is unchanged)
//     return Scaffold(
//       body: Padding(
//         padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.04),
//         child: WillPopScope(
//           onWillPop: () async {
//             if (await _controller.canGoBack()) {
//               _controller.goBack();
//               return false;
//             }
//             return true;
//           },
//           child: RefreshIndicator(
//             onRefresh: () => _controller.reload(),
//             child: Stack(
//               children: [
//                 WebViewWidget(controller: _controller),
//                 if (_loadingPercentage < 100)
//                   Center(
//                     child: CircularProgressIndicator(
//                       value: _loadingPercentage / 100.0,
//                       color: Color(0xFFEC1161),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }