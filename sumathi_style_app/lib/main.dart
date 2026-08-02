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

  // External links open panna
  Future<void> openExternalUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        debugPrint('Could not open: $url');
      }
    } catch (e) {
      debugPrint('Error opening: $url');
      debugPrint(e.toString());
    }
  }

  // Location permission
  Future<void> requestLocationPermission() async {
    final PermissionStatus status = await Permission.location.request();

    if (status.isDenied) {
      debugPrint('Location permission denied');
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  // window.open() / target="_blank" links ah intercept panna JS override
  // Idhu HTML edit pannama, ella mailto/tel/whatsapp/window.open cases um
  // FlutterApp channel vazhiya vara vaikkum
  Future<void> _injectWindowOpenOverride() async {
    await controller.runJavaScript('''
      (function() {
        window.open = function(url) {
          if (window.FlutterApp) {
            window.FlutterApp.postMessage(url);
          }
          return null;
        };

        // target="_blank" ulla anchor tags ah um intercept pannum
        document.addEventListener('click', function(e) {
          var el = e.target;
          while (el && el.tagName !== 'A') {
            el = el.parentElement;
          }
          if (el && el.tagName === 'A' && el.target === '_blank') {
            var href = el.getAttribute('href');
            if (href) {
              e.preventDefault();
              if (window.FlutterApp) {
                window.FlutterApp.postMessage(href);
              }
            }
          }
        }, true);
      })();
    ''');
  }

  // Cache clear pannitu, aprom fresh ah site load pannum
  // Idhu illama, old cached settings.html (navbar illama irundhadhu) andha
  // version WebView cache la irundhu kaanum vaipu irukku
  Future<void> _clearCacheAndLoad() async {
    await controller.clearCache();
    await controller.clearLocalStorage();
    await controller.loadRequest(
      Uri.parse(
        'https://sumathisstyles-production.up.railway.app/website.html',
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    requestLocationPermission();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      // HTML-la FlutterApp.postMessage use pannina handle aagum
      ..addJavaScriptChannel(
        'FlutterApp',
        onMessageReceived: (JavaScriptMessage message) {
          openExternalUrl(message.message);
        },
      )

      // Mail, Call, WhatsApp, UPI, Instagram external-ah open aagum
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Ovvoru page load aana pinnadi um override inject pannanum
            _injectWindowOpenOverride();
          },
          onNavigationRequest: (NavigationRequest request) async {
            final String url = request.url;
            final String lowerUrl = url.toLowerCase();

            if (lowerUrl.startsWith('mailto:') ||
                lowerUrl.startsWith('tel:') ||
                lowerUrl.startsWith('sms:') ||
                lowerUrl.startsWith('whatsapp:') ||
                lowerUrl.startsWith('https://wa.me/') ||
                lowerUrl.startsWith('upi://') ||
                lowerUrl.startsWith('intent://') ||
                lowerUrl.startsWith('instagram://')) {
              await openExternalUrl(url);

              // WebView webpage not available page show aagama stop pannum
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Cache clear pannitu, aprom main website load pannum
    _clearCacheAndLoad();

    // Android WebView location permission
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