import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewScreen(),
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

  // Call, Mail, WhatsApp open panna use aagum
  Future<void> openExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open: $url');
    }
  }

  // Location permission request pannum function
  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      debugPrint('Location permission denied');
    }
    if (status.isPermanentlyDenied) {
      // User "Don't ask again" click pannirundha, settings open pannum
      openAppSettings();
    }
  }

  @override
  void initState() {
    super.initState();

    // App start aagumbodhe location permission ketkum
    requestLocationPermission();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Website button-la irundhu Call/Mail request receive pannum
      ..addJavaScriptChannel(
        'FlutterApp',
        onMessageReceived: (JavaScriptMessage message) {
          openExternalUrl(message.message);
        },
      )
      // Mail, Call, WhatsApp link direct-ah mobile app-la open aagum
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final String url = request.url.toLowerCase();

            if (url.startsWith('mailto:') ||
                url.startsWith('tel:') ||
                url.startsWith('whatsapp:') ||
                url.startsWith('https://wa.me/')) {
              await openExternalUrl(request.url);

              // WebView error page open aagama stop pannum
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      // Un website
      ..loadRequest(
        Uri.parse(
          'https://sumathisstyles-production.up.railway.app/website.html',
        ),
      );

    // Android-la WebView geolocation permissions handle pannanum
    if (controller.platform is AndroidWebViewController) {
      final androidController =
          controller.platform as AndroidWebViewController;
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          // Website-la irundhu location kekkumbodhu, allow pannum
          return const GeolocationPermissionsResponse(
            allow: true,
            retain: true,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}