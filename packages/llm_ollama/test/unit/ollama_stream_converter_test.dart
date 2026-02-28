import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:llm_core/llm_core.dart';
import 'package:llm_ollama/src/ollama_stream_converter.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaStreamConverter', () {
    test('parses NDJSON split across transport chunk boundaries', () async {
      final frame1 = json.encode({
        'model': 'qwen3:0.6b',
        'created_at': '2024-01-01T00:00:00.000Z',
        'message': {'role': 'assistant', 'content': 'Hel'},
        'done': false,
      });
      final frame2 = json.encode({
        'model': 'qwen3:0.6b',
        'created_at': '2024-01-01T00:00:00.100Z',
        'message': {'role': 'assistant', 'content': 'lo'},
        'done': true,
      });

      final bytes = utf8.encode('$frame1\n$frame2\n');
      final splitIndex = bytes.length ~/ 2;
      final chunks = <List<int>>[
        bytes.sublist(0, splitIndex),
        bytes.sublist(splitIndex),
      ];

      final response = http.StreamedResponse(Stream.fromIterable(chunks), 200);
      final parsed = await OllamaStreamConverter.toLLMStream(response).toList();

      expect(parsed.length, 2);
      expect(parsed.first.message?.content, 'Hel');
      expect(parsed.last.message?.content, 'lo');
      expect(parsed.last.done, isTrue);
    });

    test('throws immediately when stream frame contains error', () async {
      final response = http.StreamedResponse(
        Stream.value(utf8.encode('{"error":"model does not support chat"}\n')),
        200,
      );

      expect(
        () async => OllamaStreamConverter.toLLMStream(response).toList(),
        throwsA(
          isA<LLMApiException>().having(
            (e) => e.message,
            'message',
            contains('Ollama stream error: model does not support chat'),
          ),
        ),
      );
    });

    test('throws after malformed-line retry budget is exceeded', () async {
      final response = http.StreamedResponse(
        Stream.value(
          utf8.encode('not-json-1\nnot-json-2\nnot-json-3\nnot-json-4\n'),
        ),
        200,
      );

      expect(
        () async => OllamaStreamConverter.toLLMStream(response).toList(),
        throwsA(
          isA<LLMApiException>().having(
            (e) => e.message,
            'message',
            contains('Failed to parse Ollama NDJSON stream'),
          ),
        ),
      );
    });
  });
}
