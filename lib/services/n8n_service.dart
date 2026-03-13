import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../core/config/ai_config.dart';

/// Сервис для работы с вашим сервером n8n через Webhook.
/// Позволяет вынести сложную логику парсинга, OCR или интеграций на бэкенд.
class N8nService {
  /// Отправляет текстовый запрос в n8n (например: URL рецепта или название продукта).
  /// Возвращает JSON-ответ от n8n.
  Future<dynamic> sendTextQuery(String query, {String action = 'parse', Map<String, dynamic>? contextData}) async {
    const url = AIConfig.n8nWebhookUrl;
    if (url.isEmpty || url == 'REPLACE_ME') {
      debugPrint('⚠️ N8N Webhook URL is missing. Check AIConfig.');
      return {'error': 'URL вебхука n8n не настроен.'};
    }

    try {
      final Map<String, dynamic> bodyData = {
        'action': action,
        'query': query,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (contextData != null) {
        bodyData['context'] = contextData;
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return jsonDecode(body);
      } else {
        debugPrint('❌ n8n API Error ${response.statusCode}: ${response.body}');
        return {'error': 'Ошибка сервера n8n (${response.statusCode})'};
      }
    } catch (e) {
      debugPrint('❌ n8n Request failed: $e');
      return {'error': 'Не удалось связаться с n8n: $e'};
    }
  }

  /// Отправляет изображение в n8n (например: фото чека для OCR).
  /// Сжимает фото перед отправкой.
  Future<dynamic> sendImageQuery(String imagePath,
      {String action = 'ocr'}) async {
    const url = AIConfig.n8nWebhookUrl;
    if (url.isEmpty || url == 'REPLACE_ME') {
      return {'error': 'URL вебхука n8n не настроен.'};
    }

    final compressedBytes = await _compressImage(imagePath);
    if (compressedBytes == null) {
      return {'error': 'Ошибка при сжатии изображения'};
    }

    final base64Image = base64Encode(compressedBytes);

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'action': action,
              'image_base64': base64Image,
              'mime_type': 'image/jpeg',
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return jsonDecode(body);
      } else {
        debugPrint('❌ n8n API Error ${response.statusCode}: ${response.body}');
        return {'error': 'Ошибка n8n OCR (${response.statusCode})'};
      }
    } catch (e) {
      debugPrint('❌ n8n Image Request failed: $e');
      return {'error': 'Таймаут или ошибка сети: $e'};
    }
  }

  Future<Uint8List?> _compressImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      // Сжимаем до ~1-2 МБ, чтобы n8n и API быстро его переварили
      return await FlutterImageCompress.compressWithFile(
        path,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80,
      );
    } catch (e) {
      debugPrint('⚠️ Compression failed: $e');
      try {
        return await File(path).readAsBytes();
      } catch (_) {
        return null;
      }
    }
  }
}
