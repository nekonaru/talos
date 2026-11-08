import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CommandTemplate {
  CommandTemplate({required this.id, required this.name, required this.args});

  factory CommandTemplate.fromJson(Map<String, dynamic> json) {
    return CommandTemplate(
      id: (json['id'] ?? DateTime.now().microsecondsSinceEpoch.toRadixString(16)).toString(),
      name: json['name'] as String? ?? 'Command',
      args: json['args'] as String? ?? '{url}',
    );
  }

  final String id;
  final String name;
  final String args;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'args': args};

  CommandTemplate copyWith({String? name, String? args}) {
    return CommandTemplate(id: id, name: name ?? this.name, args: args ?? this.args);
  }
}

class CommandTemplateStore extends ChangeNotifier {
  CommandTemplateStore._(this._templates, this._file);

  List<CommandTemplate> _templates;
  final File _file;

  List<CommandTemplate> get templates => List.unmodifiable(_templates);

  static Future<CommandTemplateStore> load() async {
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}${Platform.pathSeparator}commands.json');
    List<CommandTemplate> templates = [];
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          templates = [
            for (final item in decoded)
              if (item is Map<String, dynamic>) CommandTemplate.fromJson(item),
          ];
        }
      }
    } catch (_) {
      templates = [];
    }
    if (templates.isEmpty) {
      templates = [
        CommandTemplate(id: 'audio-mp3', name: 'Audio MP3 192k', args: '-x --audio-format mp3 --audio-quality 192K {url}'),
        CommandTemplate(id: 'video-720', name: 'Video max 720p', args: '-f "bv*[height<=720]+ba/b[height<=720]" {url}'),
      ];
    }
    return CommandTemplateStore._(templates, file);
  }

  Future<void> add(CommandTemplate template) async {
    _templates = [..._templates, template];
    notifyListeners();
    await _persist();
  }

  Future<void> update(CommandTemplate template) async {
    _templates = [
      for (final t in _templates) if (t.id == template.id) template else t,
    ];
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _templates = _templates.where((t) => t.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(
        const JsonEncoder.withIndent('  ').convert([for (final t in _templates) t.toJson()]),
      );
    } catch (_) {
      // Non-fatal.
    }
  }
}
