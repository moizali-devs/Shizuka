/// OpenAI API key, injected at build time via --dart-define=OPENAI_API_KEY=...
/// For production, load this from a secure backend instead.
const String kOpenAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

/// Model used for end-of-session reflections.
const String kReflectionModel = 'gpt-4o-mini';
