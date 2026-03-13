class GeminiConfig {
  // ignore: todo
  // TODO: Replace with your actual API key from https://makersuite.google.com/app/apikey
  static const String apiKey = 'AIzaSyAY4HBTX-gLMAOHZxZc33lCrXFM5q3sBRY';

  static bool get isConfigured =>
      apiKey != 'YOUR_GEMINI_API_KEY_HERE' && apiKey.isNotEmpty;
}
