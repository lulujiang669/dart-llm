# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.8] - 2026-02-26

### Added
- `OllamaMessageConverter.messagesToOllamaJson()` for list-aware conversion; derives `tool_name` from `toolCallId` via preceding assistant's `tool_calls` or synthetic ID parsing
- Fallback chain for tool_name: lookup by id, parse synthetic `tool_N_name`, or send `tool_call_id` only (Ollama supports both)
- Thorough tool response integration tests (15 cases) validating stream contract, deterministic results, error handling, tool chains, and Ollama-specific behavior

### Changed
- Tool messages now converted via `messagesToOllamaJson()`; `tool_name` encapsulated in Ollama layer, derived from `toolCallId`
- Replaced per-message `toJson()` with list-aware `messagesToOllamaJson()` for correct tool message conversion

## [0.1.7] - 2026-02-10

### Added
- `batchEmbed()` implementation: delegates to existing batch-capable `embed()` (Ollama `/api/embed` accepts an array of inputs).

## [0.1.6] - 2026-02-10

### Fixed
- Ensured Ollama tool calls always produce `LLMToolCall` instances with non-null, non-empty `id` values, synthesizing IDs when Ollama does not provide them.
- Aligned tool-calling behavior with `llm_core`'s `toolCallId` validation so that tool execution no longer fails with `Tool message must have toolCallId` when used together with `llm_core`.

## [0.1.5] - 2026-01-26

### Added
- Builder pattern for `OllamaChatRepository` via `OllamaChatRepositoryBuilder` for complex configurations
- Support for `StreamChatOptions` in `streamChat()` method
- Support for `chatResponse()` method for non-streaming complete responses
- Support for `RetryConfig` and `TimeoutConfig` for advanced request configuration
- Input validation for model names and messages

### Changed
- `streamChat()` now accepts optional `StreamChatOptions` parameter
- Improved error handling and retry logic
- Enhanced documentation

## [0.1.0] - 2026-01-19

### Added
- Initial release
- Ollama backend implementation for LLM interactions:
  - Streaming chat responses
  - Tool/function calling support
  - Vision (image) support
  - Embeddings
  - Thinking mode support
  - Model management (list, pull, show, version)
- Full compatibility with Ollama API
