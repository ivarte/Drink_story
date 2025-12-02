import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class QrWebPage extends StatefulWidget {
  const QrWebPage({super.key, required this.url});
  final String url;

  @override
  State<QrWebPage> createState() => _QrWebPageState();
}

class _QrWebPageState extends State<QrWebPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // iOS: создать контроллер с параметрами, разрешающими автоплей
    if (Platform.isIOS) {
      final params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
      _controller = WebViewController.fromPlatformCreationParams(params);
    } else {
      _controller = WebViewController();
    }

    // Android: разрешить воспроизведение без жеста пользователя
    if (_controller.platform is AndroidWebViewController) {
      final androidCtrl = _controller.platform as AndroidWebViewController;
      AndroidWebViewController.enableDebugging(false);
      androidCtrl.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
