/// Resolves a custom output folder from user rules of the form
/// `domain=folder`, one rule per line. Matching is exact or subdomain based,
/// so `youtube.com` also matches `www.youtube.com`.
String? folderForUrl(String rules, String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.isEmpty) return null;
  for (final line in rules.split(RegExp(r'\r?\n'))) {
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    final domain = line.substring(0, separator).trim().toLowerCase();
    final folder = line.substring(separator + 1).trim();
    if (domain.isEmpty || folder.isEmpty) continue;
    final matches = domain.startsWith('.')
        ? host == domain.substring(1) || host.endsWith(domain)
        : host == domain || host.endsWith('.$domain');
    if (matches) return folder;
  }
  return null;
}
