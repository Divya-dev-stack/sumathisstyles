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
  // FIX: window.__flutterOverrideInjected flag vechi, ovvoru onPageFinished
  // la duplicate ah listener add aagama guard pannirukken. Idhu illama,
  // page reload/navigate aaganum ellam oru puthu click listener stack
  // aagikittu poidum, apparam click events double/triple fire aagi
  // preventDefault() predictable illama nadakum - idhu than poster.html
  // click "aaghala" mari feel tharara reason aa irukalam.
  Future<void> _injectWindowOpenOverride() async {
    await controller.runJavaScript('''
      (function() {
        // Schemes/patterns namma always external ah open pannanum
        var EXTERNAL_PATTERNS = [
          'mailto:', 'tel:', 'sms:', 'whatsapp:',
          'https://wa.me/', 'upi:', 'intent:', 'instagram:'
        ];

        function isExternal(href) {
          if (!href) return false;
          var lower = href.toLowerCase();
          for (var i = 0; i < EXTERNAL_PATTERNS.length; i++) {
            if (lower.indexOf(EXTERNAL_PATTERNS[i]) === 0) return true;
          }
          return false;
        }

        // Idha ovvoru document (main page + same-origin iframes) mela
        // um attach pannurom. Munnadi code target="_blank" links ku
        // mattum thaan velai seiydhichu - ippo mailto/tel/sms/wa.me/
        // upi/intent/instagram links ah NEERAGA (target illama irundhalum)
        // click level la catch pannidum, WebView andha URL ah direct ah
        // load panna try pannadhu (adhaan ERR_UNKNOWN_URL_SCHEME error
        // varradhukku reason).
        function attachHandler(doc) {
          if (!doc || doc.__flutterOverrideInjected) return;
          doc.__flutterOverrideInjected = true;

          doc.addEventListener('click', function(e) {
            var el = e.target;
            while (el && el.tagName !== 'A') {
              el = el.parentElement;
            }
            if (!el || el.tagName !== 'A') return;

            var href = el.getAttribute('href');
            if (!href) return;

            if (isExternal(href) || el.target === '_blank') {
              e.preventDefault();
              e.stopPropagation();
              if (window.FlutterApp) {
                window.FlutterApp.postMessage(href);
              } else if (window.parent && window.parent.FlutterApp) {
                // iframe kulla irundha, parent window channel use pannum
                window.parent.FlutterApp.postMessage(href);
              }
            }
          }, true);
        }

        // window.open() override - andha window channel vazhiya varum
        window.open = function(url) {
          if (window.FlutterApp) {
            window.FlutterApp.postMessage(url);
          }
          return null;
        };

        attachHandler(document);

        // Same-origin iframes (example: catering.html embedded iframe)
        // kulla um handler attach pannurom
        function attachToIframes() {
          var iframes = document.querySelectorAll('iframe');
          iframes.forEach(function(frame) {
            try {
              if (frame.contentDocument) {
                attachHandler(frame.contentDocument);
              }
            } catch (err) {
              // cross-origin iframe na access panna mudiyadhu - skip
            }
            frame.addEventListener('load', function() {
              try {
                attachHandler(frame.contentDocument);
              } catch (err) {}
            });
          });
        }

        attachToIframes();

        // Iframe pinnadi dynamic ah add aana (SPA navigation), andha
        // case ah um handle panna oru chinna observer
        var observer = new MutationObserver(function() {
          attachToIframes();
        });
        observer.observe(document.body, { childList: true, subtree: true });
      })();
    ''');
  }

  // Cache clear pannitu, aprom fresh ah site load pannum
  Future<void> _clearCacheAndLoad() async {
    await controller.clearCache();
    await controller.clearLocalStorage();
    await controller.loadRequest(
      Uri.parse(
        'https://r9tlh3kw-8080.inc1.devtunnels.ms/#'
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
          debugPrint('FlutterApp channel message: ${message.message}');
          openExternalUrl(message.message);
        },
      )

      // Mail, Call, WhatsApp, UPI, Instagram external-ah open aagum
      // poster.html mathiri internal pages normal ah navigate aagum
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('PAGE FINISHED: $url');
            // Ovvoru page load aana pinnadi um override inject pannanum
            // (guard flag irukkardhala, already injected na re-inject aagadhu)
            _injectWindowOpenOverride();
          },
          onNavigationRequest: (NavigationRequest request) async {
            final String url = request.url;
            final String lowerUrl = url.toLowerCase();

            // DEBUG: idha vachi terminal/logcat la check pannu -
            // poster.html click pannumbodhu idhu print aaguthaa nu paaru.
            // Print aagala na, click event WebView ku reach aagala -
            // adhu CSS/touch/overlay issue on website.html side.
            // Print aagi but screen blank na - WebViewWidget height/
            // rendering issue.
            debugPrint('NAV REQUEST: $url');

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