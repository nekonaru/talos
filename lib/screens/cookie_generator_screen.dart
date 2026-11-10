import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app_scope.dart';
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
      ..setBackgroundColor(const Color(0xFF161311))
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (change) {
            if (change.url != null) {
              _urlController.text = change.url!;
            }
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
    final uri = Uri.tryParse(_urlController.text.trim());
    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      _controller?.loadRequest(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a full https URL')),
      );
    }
  }

  Future<void> _saveCookies() async {
    final controller = _controller;
    if (controller == null) return;
    final manager = TalosScope.of(context);

    setState(() => _saving = true);
    try {
      final uri = Uri.tryParse(_urlController.text.trim()) ?? Uri.parse('https://www.youtube.com');
      final cookies = await WebViewCookieManager().getCookies(domain: uri);

      if (!mounted) return;
      if (cookies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cookies found. Sign in first, then save.')),
        );
        return;
      }

      final buffer = StringBuffer()..writeln('# Talos cookie export');
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
      await file.writeAsString(buffer.toString());
      await manager.settings.mutate((s) => s.copyWith(cookiesPath: file.path));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cookies.length} cookies saved. They are used for yt-dlp from now.'),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l.cookieGenerator),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
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
                        tooltip: 'Go',
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
    );
  }
}
