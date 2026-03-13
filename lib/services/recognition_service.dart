import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../core/config/ai_config.dart';

class RecognitionService {
  bool _isInitialized = false;

  // Free vision models on OpenRouter — tried in order until one succeeds
  static const List<String> _modelFallbacks = [
    'meta-llama/llama-3.2-11b-vision-instruct:free',
    'qwen/qwen2.5-vl-32b-instruct:free',
    'google/gemma-3-12b-it:free',
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint(
        '✅ RecognitionService initialized (OpenRouter multi-model mode)');
  }

  Future<Map<String, dynamic>> processImage(String path) async {
    if (!_isInitialized) await initialize();

    final compressedBytes = await _compressImage(path);
    if (compressedBytes == null) {
      return {
        'error': 'Ошибка обработки изображения',
        'suggestions': <String>[]
      };
    }

    final base64Image = base64Encode(compressedBytes);

    // If proxy server is configured — route through PC with VPN
    if (AIConfig.useProxy) {
      try {
        debugPrint('🔀 Routing through proxy: ${AIConfig.proxyUrl}');
        return await _callProxy(base64Image);
      } catch (e) {
        debugPrint('⚠️ Proxy failed, falling back to direct: $e');
        // Fall through to direct API calls below
      }
    }

    // Try each model in order until one works
    for (final model in _modelFallbacks) {
      try {
        debugPrint('🔄 Trying model: $model');
        final result = await _callOpenRouter(base64Image, model);
        return result;
      } catch (e) {
        debugPrint('⚠️ Model $model failed: $e');
        continue;
      }
    }

    return {
      'error': 'Все модели недоступны. Проверьте интернет и API-ключ.',
      'suggestions': <String>[]
    };
  }

  Future<Uint8List?> _compressImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('❌ Image file not found: $path');
        return null;
      }
      final result = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: 512,
        minHeight: 512,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      final originalSize = await file.length();
      debugPrint('✅ Compressed: $originalSize → ${result?.length} bytes');
      return result;
    } catch (e) {
      debugPrint('⚠️ Compression failed, using original: $e');
      try {
        return await File(path).readAsBytes();
      } catch (e2) {
        debugPrint('❌ Cannot read image: $e2');
        return null;
      }
    }
  }

  Future<Map<String, dynamic>> _callOpenRouter(
      String base64Image, String model) async {
    const prompt =
        'На фото изображена еда. Определи ЧТО ИМЕННО изображено и дай РОВНО 3 варианта названия на РУССКОМ языке через запятую — от конкретного к общему. '
        'Пример ответа: "Зелёное яблоко, Яблоко Гренни Смит, Яблоко". '
        'ТОЛЬКО список через запятую. БЕЗ нумерации, БЕЗ пояснений, БЕЗ markdown. '
        'Если на фото НЕ еда — ответь одним словом: "Нееда".';

    final response = await http
        .post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${AIConfig.openRouterKey}',
            'HTTP-Referer': 'https://fruktik.app',
            'X-Title': 'FRUktik Food Recognition',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.1,
            'max_tokens': 80,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,$base64Image',
                      'detail': 'low', // Cheaper/faster — enough for food ID
                    }
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));

    // Always decode with UTF-8 explicitly
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      debugPrint('❌ OpenRouter [$model] ${response.statusCode}: $body');
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(body);
    final raw = (data['choices']?[0]?['message']?['content'] ?? '').trim();
    debugPrint('🤖 [$model] raw: $raw');

    return _parseResponse(raw);
  }

  Map<String, dynamic> _parseResponse(String raw) {
    if (raw.isEmpty) throw Exception('Пустой ответ от модели');

    // Strip any markdown wrapping (``` or **bold** etc.)
    var text = raw
        .replaceAll(RegExp(r'```[a-z]*'), '')
        .replaceAll('```', '')
        .replaceAll('**', '')
        .trim();

    // Check for "not food" signals in Russian and English
    final lower = text.toLowerCase();
    if (lower.contains('нееда') ||
        lower.contains('не еда') ||
        lower.contains('not food') ||
        lower.contains('no food') ||
        lower.contains('не является едой') ||
        lower.contains('не содержит еды')) {
      throw Exception('Еда не распознана');
    }

    // Split by comma or newline
    var suggestions = text
        .split(RegExp(r'[,\n]'))
        .map((s) => s
            .trim()
            .replaceAll(RegExp(r'^\d+[\.\)]?\s*'), '') // Remove "1. " prefixes
            .trim())
        .where((s) => s.isNotEmpty && s.length > 1)
        .take(3)
        .toList();

    if (suggestions.isEmpty) {
      throw Exception('Не удалось разобрать ответ: $raw');
    }

    debugPrint('✅ Parsed suggestions: ${suggestions.join(' | ')}');
    return {
      'name': suggestions.first,
      'suggestions': suggestions,
    };
  }

  /// Sends image to the proxy server running on the PC (with VPN)
  Future<Map<String, dynamic>> _callProxy(String base64Image) async {
    final response = await http
        .post(
          Uri.parse('${AIConfig.proxyUrl}/recognize'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'image_base64': base64Image}),
        )
        .timeout(const Duration(seconds: 60));

    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw Exception('Proxy error ${response.statusCode}: $body');
    }

    final data = jsonDecode(body);
    final suggestions = List<String>.from(data['suggestions'] ?? []);
    final name = data['name'] as String? ?? suggestions.firstOrNull ?? '';
    debugPrint('✅ Proxy result: $name (model: ${data['model_used']})');
    return {'name': name, 'suggestions': suggestions};
  }

  void dispose() {
    _isInitialized = false;
  }
}
