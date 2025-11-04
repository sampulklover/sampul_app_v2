import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static String? _apiKey;
  static String? _model;

  static Future<void> initialize() async {
    _apiKey = dotenv.env['OPENROUTER_API_KEY'];
    _model = dotenv.env['OPENROUTER_MODEL'];
    
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OPENROUTER_API_KEY not found in environment variables');
    }
    
    if (_model == null || _model!.isEmpty) {
      throw Exception('OPENROUTER_MODEL not found in environment variables');
    }
  }

  static Future<String> sendMessage(String message, {String? model, String? context}) async {
    try {
      if (_apiKey == null || _model == null) {
        await initialize();
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://sampul.app', // Optional: for tracking
          'X-Title': 'Sampul AI Chat', // Optional: for tracking
        },
        body: jsonEncode({
          'model': model ?? _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are Sampul AI, a helpful assistant for estate planning and will management. You help users with questions about creating wills, managing assets, family planning, and estate planning. Be friendly, professional, and knowledgeable about these topics. Keep answers concise (2–4 short sentences). Use bullet points only when listing items. Avoid long paragraphs.'
            },
            if (context != null && context.isNotEmpty)
              {
                'role': 'system',
                'content': 'User context (private): ' + context,
              },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'max_tokens': 220,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        } else {
          throw Exception('No choices in response: ${response.body}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<String>> getAvailableModels() async {
    if (_apiKey == null) {
      await initialize();
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/models'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((model) => model['id'] as String)
          .toList();
    } else {
      throw Exception('Failed to get models from OpenRouter: ${response.statusCode}');
    }
  }

  static Future<bool> testConnection() async {
    try {
      await initialize();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Stream<String> sendMessageStream(String message, {String? model, String? context}) async* {
    try {
      if (_apiKey == null || _model == null) {
        await initialize();
      }

      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'));
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://sampul.app',
        'X-Title': 'Sampul AI Chat',
      });

      request.body = jsonEncode({
        'model': model ?? _model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are Sampul AI, a helpful assistant for estate planning and will management. You help users with questions about creating wills, managing assets, family planning, and estate planning. Be friendly, professional, and knowledgeable about these topics. Keep answers concise (2–4 short sentences). Use bullet points only when listing items. Avoid long paragraphs.'
          },
          if (context != null && context.isNotEmpty)
            {
              'role': 'system',
              'content': 'User context (private): ' + context,
            },
          {
            'role': 'user',
            'content': message,
          }
        ],
        'max_tokens': 220,
        'temperature': 0.5,
        'stream': true,
      });

      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                return;
              }
              
              try {
                final jsonData = jsonDecode(data);
                if (jsonData['choices'] != null && 
                    jsonData['choices'].isNotEmpty && 
                    jsonData['choices'][0]['delta'] != null &&
                    jsonData['choices'][0]['delta']['content'] != null) {
                  yield jsonData['choices'][0]['delta']['content'];
                }
              } catch (e) {
                // Skip invalid JSON lines
                continue;
              }
            }
          }
        }
      } else {
        throw Exception('HTTP ${streamedResponse.statusCode}');
      }
    } catch (e) {
      // Fallback to non-streaming if streaming fails
      final response = await sendMessage(message, model: model, context: context);
      yield response;
    }
  }
}
