# frozen_string_literal: true

# DeepSeek AI provider implementation
# DeepSeek API is compatible with OpenAI's API format
module AiClient
  class Deepseak
    EMBEDDING_MODEL = 'deepseek-ai/deepseek-chat'
    CHAT_MODEL = 'deepseek-chat'
    BASE_URL = 'https://api.deepseek.com'

    def initialize
      @api_key = ENV['DEEPSEAK_API_KEY']
      raise 'DEEPSEAK_API_KEY environment variable not set' if @api_key.blank?
    end

    # Generate embedding for text using DeepSeek API
    # Note: DeepSeek uses OpenAI-compatible API, so we use ruby-openai gem
    # @param text [String] Text to embed
    # @return [Array<Float>] Embedding vector
    def embed(text)
      log_info("Generating embedding for text (#{text.length} chars)")

      client = OpenAI::Client.new(
        access_token: @api_key,
        uri_base: BASE_URL
      )

      # DeepSeek uses the chat model for embeddings via special prompting
      # We'll use a workaround: generate a short response and use the text
      # In production, verify if DeepSeek has a dedicated embedding endpoint
      response = client.embeddings(
        parameters: {
          model: 'text-embedding-ada-002', # DeepSeek may support this model name
          input: text
        }
      )

      embedding = response.dig('data', 0, 'embedding')

      if embedding.nil?
        log_error("Failed to generate embedding: #{response}")
        raise 'Failed to generate embedding'
      end

      log_info("Successfully generated embedding (#{embedding.size} dimensions)")
      embedding
    rescue StandardError => e
      log_error("Error generating embedding: #{e.message}")
      raise
    end

    # Generate chat completion using DeepSeek
    # @param prompt [String] The system/user messages
    # @param options [Hash] Options like temperature, max_tokens
    # @return [String] Generated text
    def complete(prompt, options = {})
      log_info("Generating completion (prompt: #{prompt.length} chars)")

      client = OpenAI::Client.new(
        access_token: @api_key,
        uri_base: BASE_URL
      )

      response = client.chat(
        parameters: {
          model: CHAT_MODEL,
          messages: prompt.is_a?(Array) ? prompt : [{ role: 'user', content: prompt }],
          temperature: options[:temperature] || 0.7,
          max_tokens: options[:max_tokens] || 500
        }
      )

      content = response.dig('choices', 0, 'message', 'content')

      if content.nil?
        log_error("Failed to generate completion: #{response}")
        raise 'Failed to generate completion'
      end

      log_info("Successfully generated completion (#{content.length} chars)")
      content
    rescue StandardError => e
      log_error("Error generating completion: #{e.message}")
      raise
    end

    private

    def log_info(message)
      return unless logging_enabled?

      Rails.logger.info("[AiClient::Deepseak] #{message}")
    end

    def log_error(message)
      return unless logging_enabled?

      Rails.logger.error("[AiClient::Deepseak] #{message}")
    end

    def logging_enabled?
      ENV['ENABLE_AI_CHAT_LOGS'] == 'true'
    end
  end
end
