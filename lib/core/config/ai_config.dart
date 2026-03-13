class AIConfig {
  // OpenRouter API (работает в РФ без VPN)
  // Передавай через: --dart-define=OPENROUTER_API_KEY=sk-or-v1-...
  static const String openRouterKey =
      String.fromEnvironment('OPENROUTER_API_KEY');

  // Proxy server URL (оставить пустым = прямые запросы, заполнить = через ПК с VPN)
  // Пример: 'http://192.168.1.100:8000'
  // Передавай через: --dart-define=PROXY_URL=http://192.168.0.108:8000
  static const String proxyUrl =
      String.fromEnvironment('PROXY_URL');

  /// true = использовать прокси на ПК
  static bool get useProxy => proxyUrl.isNotEmpty;

  // n8n Webhook URL for external parsing/integrations
  // Передавай через: --dart-define=N8N_WEBHOOK_URL=https://...
  static const String n8nWebhookUrl = String.fromEnvironment('N8N_WEBHOOK_URL',
      defaultValue: 'https://akumochizake.app.n8n.cloud/webhook/fruktik-ai');
}
