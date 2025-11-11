import 'package:flutter/material.dart';
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
  bool _pageLoaded = false; // Track if page is fully loaded

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setBackgroundColor(const Color(0x00000000))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
              _pageLoaded = true; // Mark page as loaded
            });
          },
          onWebResourceError: (error) {
            if (_pageLoaded && !error.description.contains('Blocked by client')) {
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Failed to load page: ${error.description}'),
              //   ),
              // );
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.parse(request.url);

            if (request.url.startsWith('https://api.whatsapp.com')) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text('Could not launch WhatsApp.')),
                // );
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
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.04),
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
}
