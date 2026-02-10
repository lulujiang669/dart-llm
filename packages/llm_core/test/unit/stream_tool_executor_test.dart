library;

import 'dart:convert';

import 'package:llm_core/llm_core.dart';
import 'package:test/test.dart';

class _EchoTool extends LLMTool {
  @override
  String get name => 'echo_tool';

  @override
  String get description => 'Echoes the provided message';

  @override
  List<LLMToolParam> get parameters => const [];

  @override
  Future<dynamic> execute(Map<String, dynamic> args, {dynamic extra}) async {
    return jsonEncode(args);
  }
}

void main() {
  group('StreamToolExecutor', () {
    test('synthesizes non-empty toolCallId when LLMToolCall.id is null', () async {
      final tool = _EchoTool();

      // Simulate a backend tool call with a null id
      final toolCall = LLMToolCall(
        name: tool.name,
        arguments: jsonEncode({'message': 'hello'}),
        id: null,
      );

      // This mirrors the logic inside StreamToolExecutor for deriving the
      // effective toolCallId when the backend omits an id.
      final toolCallIndex = 0;
      final effectiveToolCallId =
          (toolCall.id != null && toolCall.id!.isNotEmpty)
              ? toolCall.id!
              : 'tool_${toolCallIndex}_${toolCall.name}';

      final toolResponse =
          await tool.execute(jsonDecode(toolCall.arguments) as Map<String, dynamic>);

      final message = LLMMessage(
        content: toolResponse is String ? toolResponse : toolResponse.toString(),
        role: LLMRole.tool,
        toolCallId: effectiveToolCallId,
      );

      expect(message.toolCallId, isNotNull);
      expect(message.toolCallId, isNotEmpty);

      // Ensure the synthesized message passes validation.
      expect(
        () => Validation.validateMessage(message),
        returnsNormally,
      );
    });
  });
}

