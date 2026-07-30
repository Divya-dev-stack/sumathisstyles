import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final String url = request.url;

            // Email link
            if (url.startsWith('mailto:')) {
              final Uri emailUri = Uri.parse(url);

              await launchUrl(
                emailUri,
                mode: LaunchMode.externalApplication,
              );

              // WebView-la error page open aagama stop pannum
              return NavigationDecision.prevent;
            }

            // Phone call link
            if (url.startsWith('tel:')) {
              final Uri phoneUri = Uri.parse(url);

              await launchUrl(
                phoneUri,
                mode: LaunchMode.externalApplication,
              );

              return NavigationDecision.prevent;
            }

            // WhatsApp link
            if (url.startsWith('whatsapp:') ||
                url.startsWith('https://wa.me')) {
              final Uri whatsappUri = Uri.parse(url);

              await launchUrl(
                whatsappUri,
                mode: LaunchMode.externalApplication,
              );

              return NavigationDecision.prevent;
            }

            // Other website links WebView-kulla open aagum
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://sumathisstyles-production.up.railway.app/website.html',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(
          controller: controller,
        ),
      ),
    );
  }
}