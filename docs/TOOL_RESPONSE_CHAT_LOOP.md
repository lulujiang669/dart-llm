# Tool Response Chat Loop - Stream Contract

This document describes how tool calls and tool results flow through the chat stream, per [OpenAI function calling](https://developers.openai.com/api/docs/guides/function-calling/) and [streaming](https://developers.openai.com/api/docs/guides/function-calling/#streaming) specifications.

## Stream Chunk Types

Consumers of `streamChat()` receive three types of chunks. Handle all three to display the full tool calling flow:

### 1. Content Chunks (Assistant Text)

- `chunk.message?.content` - Incremental text from the model
- `chunk.message?.role` - `LLMRole.assistant`
- `chunk.message?.thinking` - Optional reasoning content (when `think: true`)

### 2. Tool Call Chunks (Model Requests Tools)

- `chunk.message?.toolCalls` - Non-null when the model requests tool execution
- Typically on the final chunk of a round (`chunk.done == true`)
- Each `LLMToolCall` has: `name`, `arguments`, `id` (or synthesized)

### 3. Tool Result Chunks (Tool Execution Output)

- `chunk.message?.role == LLMRole.tool`
- `chunk.message?.content` - The tool's return value
- `chunk.message?.toolCallId` - Links to the tool call (canonical identifier)

Tool result chunks are emitted by the executor after each tool runs, before the next API request. To display "Tool X returned: Y", build a map from tool call chunks (`toolCallId -> toolName` from `message?.toolCalls`) and look up the name when processing tool result chunks.

## Flow Summary

```
User message
    |
    v
[API Request 1] --> Stream: content chunks, then chunk with toolCalls
    |
    v
Executor runs tools --> Stream: tool result chunks (role: tool)
    |
    v
[API Request 2] with [user, assistant(tool_calls), tool(result), ...]
    |
    v
Stream: content chunks (model's final response)
```

## Backend Differences

- **OpenAI/ChatGPT:** Tool messages use `tool_call_id`. Stream includes `delta.tool_calls`.
- **Ollama:** Uses `tool_name` for tool messages. The Ollama message converter derives `tool_name` from `toolCallId` (via preceding assistant's `tool_calls` or synthetic ID parsing) and sends both `tool_name` and `tool_call_id` when possible.

## Code Path

- Tool execution: [packages/llm_core/lib/src/tool_executor.dart](packages/llm_core/lib/src/tool_executor.dart)
- Tool result emission: `StreamToolExecutor.executeTools` yields `LLMChunk` with `role: LLMRole.tool` after each tool runs
- Ollama message format: [packages/llm_ollama/lib/src/message_converter.dart](packages/llm_ollama/lib/src/message_converter.dart)
