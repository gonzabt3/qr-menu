# frozen_string_literal: true

# Service to interact with AI providers (DeepSeek, OpenAI)
# Provides abstraction for embedding generation and text completion
class AiClient
  class << self
    # Generate embedding vector for given text
    # @param text [String] Text to embed
    # @return [Array<Float>] Embedding vector
    def embed(text)
      provider.embed(text)
    end

    # Generate text completion based on prompt
    # @param prompt [String] The prompt/conversation messages
    # @param options [Hash] Additional options (temperature, max_tokens, etc.)
    # @return [String] Generated text
    def complete(prompt, options = {})
      provider.complete(prompt, options)
    end

    private

    def provider
      @provider ||= case ENV.fetch('AI_PROVIDER', 'deepseak').downcase
                    when 'openai'
                      AiClient::OpenAI.new
                    when 'deepseak'
                      AiClient::Deepseak.new
                    else
                      raise "Unknown AI provider: #{ENV['AI_PROVIDER']}"
                    end
    end
  end
end
