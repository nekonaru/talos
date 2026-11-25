import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app_scope.dart';
import '../core/secure_file.dart';
import '../gen/app_localizations.dart';

/// Sign into a supported site in an in-app WebView, then export the session
/// cookies as a cookies.txt file for yt-dlp.
class CookieGeneratorScreen extends StatefulWidget {
  const CookieGeneratorScreen({super.key});

  @override
  State<CookieGeneratorScreen> createState() => _CookieGeneratorScreenState();
}

class _CookieGeneratorScreenState extends State<CookieGeneratorScreen> {
  WebViewController? _controller;
  final _urlController = TextEditingController(text: 'https://www.youtube.com');
  bool _saving = false;
  bool _webCanGoBack = false;
  String? _loadedUrl;

  @override
  void initState() {
    super.initState();
    // WebView is only supported on Android and iOS.
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    final controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (change) {
            if (change.url != null) {
              _loadedUrl = change.url;
              _urlController.text = change.url!;
            }
            // Keep the system Back gesture in sync with WebView history.
            _controller?.canGoBack().then((can) {
              if (mounted && can != _webCanGoBack) {
                setState(() => _webCanGoBack = can);
              }
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_urlController.text));
    _controller = controller;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _reload() {
    final l = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(_urlController.text.trim());
    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      _controller?.loadRequest(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invalidUrl)),
      );
    }
  }

  Future<void> _saveCookies() async {
    final controller = _controller;
    if (controller == null) return;
    final manager = TalosScope.of(context);

    // Export cookies for the page actually loaded, not for a URL the user
    // may have typed without navigating to it.
    final text = (_loadedUrl ?? _urlController.text).trim();
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidUrl)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final cookies = await WebViewCookieManager().getCookies(domain: uri);

      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      if (cookies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.noCookies)),
        );
        return;
      }

      final buffer = StringBuffer()..writeln('# Talos cookie export');
      // webview_flutter 4.x does not expose a cookie's Secure flag or expiry,
      // so the Netscape fields below use the session-cookie defaults. yt-dlp
      // still receives the correct name, value, domain and path.
      for (final cookie in cookies) {
        final flag = cookie.domain.startsWith('.') ? 'TRUE' : 'FALSE';
        buffer.writeln([
          cookie.domain,
          flag,
          cookie.path,
          'FALSE',
          '0',
          cookie.name,
          cookie.value,
        ].join('\t'));
      }

      final support = await getApplicationSupportDirectory();
      final file = File('${support.path}${Platform.pathSeparator}talos_cookies.txt');
      await writeFileAtomic(file, buffer.toString());
      await restrictFileToOwner(file);
      await manager.settings.mutate((s) => s.copyWith(cookiesPath: file.path));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.cookiesSaved(cookies.length))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final controller = _controller;

    return PopScope(
      canPop: !_webCanGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final web = _controller;
        if (web != null && await web.canGoBack()) {
          await web.goBack();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(l.cookieGenerator),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.reloadPage,
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          // Back is captured by WebView history. An explicit close action
          // always leaves the screen without walking the whole history.
          IconButton(
            tooltip: l.close,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: controller == null
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.cookieGeneratorHint,
                textAlign: TextAlign.center,
              ),
            ))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _reload(),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: l.goTo,
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _reload,
                      ),
                    ],
                  ),
                ),
                Expanded(child: WebViewWidget(controller: controller)),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _saveCookies,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_circle_outline),
                        label: Text(l.save),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
