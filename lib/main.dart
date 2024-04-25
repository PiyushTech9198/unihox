import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class MyUrlState extends ChangeNotifier {
  String url = 'https://unihox.com/';

  void updateUrl(String newUrl) {
    url = newUrl;
    notifyListeners();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unihox',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider(
        create: (_) => MyUrlState(),
        child: const WebViewPage(),
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final Completer<InAppWebViewController> _controller =
      Completer<InAppWebViewController>();
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final url = Provider.of<MyUrlState>(context).url;

    return Scaffold(
      key: _key,
      // appBar: AppBar(
      //   title: ClipRRect(
      //     borderRadius: BorderRadius.circular(5),
      //     child: Image.asset(
      //       "assets/unihox.png",
      //       fit: BoxFit.cover,
      //       height: 50,
      //       width: 150,
      //     ),
      //   ),
      //   actions: <Widget>[
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: () => _reload(),
      //     ),
      //     IconButton(
      //       icon: const Icon(Icons.arrow_back),
      //       onPressed: () => _goBack(),
      //     ),
      //     IconButton(
      //       icon: const Icon(Icons.arrow_forward),
      //       onPressed: () => _goForward(),
      //     ),
      //   ],
      // ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(url)),
            onWebViewCreated: (InAppWebViewController webViewController) {
              _controller.complete(webViewController);
            },
            onLoadStart: (controller, url) => _showLoading(),
            onLoadStop: (controller, url) {
              Provider.of<MyUrlState>(context, listen: false)
                  .updateUrl(url.toString());
              _hideLoading();
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              if (navigationAction.request.url
                      .toString()
                      .startsWith('mailto:') ||
                  navigationAction.request.url.toString().startsWith('tel:')) {
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading) _loadingIndicator(),
        ],
      ),
    );
  }

  bool _isLoading = false;

  Widget _loadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  void _showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  void _reload() async {
    try {
      final controller = await _controller.future;
      controller.reload();
    } catch (e) {
      _showErrorSnackBar("Error reloading");
    }
  }

  void _goBack() async {
    try {
      final controller = await _controller.future;
      if (await controller.canGoBack()) {
        controller.goBack();
      } else {
        _showErrorSnackBar("No back history");
      }
    } catch (e) {
      _showErrorSnackBar("Error going back");
    }
  }

  void _goForward() async {
    try {
      final controller = await _controller.future;
      if (await controller.canGoForward()) {
        controller.goForward();
      } else {
        _showErrorSnackBar("No forward history");
      }
    } catch (e) {
      _showErrorSnackBar("Error going forward");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
