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

  // Mail, Call, WhatsApp, UPI links external app-la open aagum
  Future<void> openExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        debugPrint('Could not open: $url');
      }
    } catch (e) {
      debugPrint('Could not open: $url');
      debugPrint(e.toString());
    }
  }

  // Location permission request pannum
  Future<void> requestLocationPermission() async {
    final PermissionStatus status = await Permission.location.request();

    if (status.isDenied) {
      debugPrint('Location permission denied');
    }

    if (status.isPermanentlyDenied) {
      // "Don't ask again" select pannirundha app settings open aagum
      await openAppSettings();
    }
  }

  @override
  void initState() {
    super.initState();

    // App start aagumbodhu location permission ketkum
    requestLocationPermission();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      // Website-la irundhu Call/Mail/UPI request receive pannum
      ..addJavaScriptChannel(
        'FlutterApp',
        onMessageReceived: (JavaScriptMessage message) {
          openExternalUrl(message.message);
        },
      )

      // Mail, Call, WhatsApp, UPI links direct-ah mobile app-la open aagum
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final String url = request.url.toLowerCase();

            if (url.startsWith('mailto:') ||
                url.startsWith('tel:') ||
                url.startsWith('whatsapp:') ||
                url.startsWith('https://wa.me/') ||
                url.startsWith('upi://')) {
              await openExternalUrl(request.url);

              // WebView-la error page open aagama stop pannum
              return NavigationDecision.prevent;
            }

            // Other website links WebView-kulla open aagum
            return NavigationDecision.navigate;
          },
        ),
      )

      // Un website URL
      ..loadRequest(
        Uri.parse(
          'https://sumathisstyles-production.up.railway.app/website.html',
        ),
      );

    // Android WebView geolocation permission handle pannum
    if (controller.platform is AndroidWebViewController) {
      final AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;

      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
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
      body: SafeArea(
        child: WebViewWidget(
          controller: controller,
        ),
      ),
    );
  }
}