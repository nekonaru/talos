import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'engine/models.dart';
import 'history_store.dart';
import 'secure_file.dart';

/// Persisted snapshot of the active queue. Only pending work is stored: a
/// running task was killed with the process and is resumed as queued, with its
/// original request and retry count intact.
class QueuedDownload {
  const QueuedDownload({
    required this.id,
    required this.title,
    required this.url,
    required this.kind,
    required this.request,
    this.thumbnailUrl,
    this.attempts = 0,
  });

  final String id;
  final String title;
  final String url;
  final HistoryKind kind;
  final DownloadRequest request;
  final String? thumbnailUrl;
  final int attempts;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'kind': kind.name,
        'request': request.toJson(),
        'thumbnailUrl': thumbnailUrl,
        'attempts': attempts,
      };

  factory QueuedDownload.fromJson(Map<String, dynamic> json) {
    final request = json['request'];
    final title = json['title'] as String?;
    final id = json['id'] as String?;
    if (request is! Map<String, dynamic> ||
        title == null ||
        title.isEmpty ||
        id == null ||
        id.isEmpty) {
      throw const FormatException('Malformed queued download');
    }
    final parsedRequest = DownloadRequest.fromJson(request);
    final kindName = json['kind'] as String?;
    final kind = HistoryKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => HistoryKind.video,
    );
    return QueuedDownload(
      id: id,
      title: title,
      url: parsedRequest.url,
      kind: kind,
      request: parsedRequest,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}

class QueueStore {
  static Future<List<QueuedDownload>> load() async {
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}${Platform.pathSeparator}queue.json');
    try {
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      final result = <QueuedDownload>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          result.add(QueuedDownload.fromJson(item));
        } catch (_) {
          // One corrupt row must not discard the rest of the queue.
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(Iterable<QueuedDownload> downloads) async {
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}${Platform.pathSeparator}queue.json');
    try {
      await file.parent.create(recursive: true);
      await writeFileAtomic(
        file,
        const JsonEncoder.withIndent('  ').convert([
          for (final item in downloads) item.toJson(),
        ]),
      );
      await restrictFileToOwner(file);
    } catch (_) {
      // Persistence is best effort; the in-memory queue still works.
    }
  }
}
