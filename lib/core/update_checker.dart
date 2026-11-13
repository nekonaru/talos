import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_info.dart';

enum UpdateCheckStatus { updateAvailable, upToDate, unreachable, noReleases }

class UpdateInfo {
  UpdateInfo({
    required this.tagName,
    required this.name,
    required this.htmlUrl,
    required this.body,
    required this.publishedAt,
  });

  final String tagName;
  final String name;
  final String htmlUrl;
  final String body;
  final String publishedAt;
}

class UpdateCheckResult {
  UpdateCheckResult(this.status, {this.info});

  final UpdateCheckStatus status;
  final UpdateInfo? info;

  bool get upToDate => status == UpdateCheckStatus.upToDate;
  bool get updateAvailable => status == UpdateCheckStatus.updateAvailable;
}

/// Checks GitHub's public Releases API for the newest Talos release and
/// compares it to [TalosInfo.appVersion]. No network call blocks startup:
/// callers decide when to poll.
class UpdateChecker {
  const UpdateChecker();

  Future<UpdateCheckResult> check() async {
    final data = await _fetchLatestRelease();
    if (data == null) {
      return UpdateCheckResult(UpdateCheckStatus.unreachable);
    }
    final tagName = (data['tag_name'] as String?)?.trim() ?? '';
    if (tagName.isEmpty) {
      return UpdateCheckResult(UpdateCheckStatus.noReleases);
    }
    final htmlUrl = (data['html_url'] as String?)?.trim() ?? '';
    final name = (data['name'] as String?)?.trim() ?? tagName;
    final body = (data['body'] as String?)?.trim() ?? '';
    final publishedAt = (data['published_at'] as String?)?.trim() ?? '';

    if (isNewer(stripV(tagName), TalosInfo.appVersion)) {
      return UpdateCheckResult(
        UpdateCheckStatus.updateAvailable,
        info: UpdateInfo(
          tagName: tagName,
          name: name,
          htmlUrl: htmlUrl.isNotEmpty ? htmlUrl : 'https://github.com/nekonaru/talos/releases',
          body: body,
          publishedAt: publishedAt,
        ),
      );
    }
    return UpdateCheckResult(UpdateCheckStatus.upToDate);
  }

  static String stripV(String tag) {
    var t = tag.trim();
    if (t.startsWith('v') || t.startsWith('V')) return t.substring(1);
    return t;
  }

  /// Returns true if [candidate] is newer than [current].
  /// "0.4.0" vs "0.3.x"; zero compared numerically; letters in pre-release
  /// labels ("1.0.0-rc1") are ignored for comparison.
  static bool isNewer(String candidate, String current) {
    final c = parseCore(candidate);
    final r = parseCore(current);
    for (var i = 0; i < 3; i++) {
      if (c[i] > r[i]) return true;
      if (c[i] < r[i]) return false;
    }
    return false;
  }

  static List<int> parseCore(String version) {
    // Keep only the dotted numeric prefix. Any suffix after "+" or "-" is ignored.
    final core = version.split(RegExp(r'[+\-]')).first;
    final parts = core.split('.');
    final out = <int>[];
    for (var i = 0; i < 3; i++) {
      out.add(i < parts.length ? (int.tryParse(parts[i].trim()) ?? 0) : 0);
    }
    return out;
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(Uri.parse('https://api.github.com/repos/nekonaru/talos/releases/latest'))
          .timeout(const Duration(seconds: 10));
      request.headers
          .set('user-agent', 'Talos/${TalosInfo.appVersion}');
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
