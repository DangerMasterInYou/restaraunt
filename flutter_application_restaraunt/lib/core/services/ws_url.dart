/// Строит URL веб-сокета из базового адреса API и пути.
///
/// - Нативные сборки: apiSiteUrl абсолютный (http/https) -> меняем схему на ws/wss.
/// - Web за nginx: apiSiteUrl относительный ('/api') -> берём схему и хост из
///   адреса текущей страницы (Uri.base работает и в вебе, и нативно).
String resolveWsUrl(String apiSiteUrl, String path) {
  if (apiSiteUrl.startsWith('http')) {
    return apiSiteUrl.replaceFirst('http', 'ws') + path;
  }
  final base = Uri.base;
  final scheme = base.scheme == 'https' ? 'wss' : 'ws';
  return '$scheme://${base.authority}$apiSiteUrl$path';
}
