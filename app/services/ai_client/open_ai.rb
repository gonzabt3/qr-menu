# frozen_string_literal: true

# OpenAI provider implementation
module AiClient
  class OpenAi
    EMBEDDING_MODEL = 'text-embedding-ada-002'
    CHAT_MODEL = 'gpt-3.5-turbo'

    def initialize
      @api_key = ENV['OPENAI_API_KEY']
      raise 'OPENAI_API_KEY environment variable not set' if @api_key.blank?
    end

    # Generate embedding for text using OpenAI API
    # @param text [String] Text to embed
    # @return [Array<Float>] Embedding vector (1536 dimensions for ada-002)
    def embed(text)
      log_info("Generating embedding for text (#{text.length} chars)")

      client = ::OpenAI::Client.new(access_token: @api_key)

      response = client.embeddings(
        parameters: {
          model: EMBEDDING_MODEL,
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

    # Generate chat completion using OpenAI
    # @param prompt [String|Array] The system/user messages
    # @param options [Hash] Options like temperature, max_tokens
    # @return [String] Generated text
    def complete(prompt, options = {})
      log_info("Generating completion (prompt: #{prompt.is_a?(Array) ? prompt.size : prompt.length})")

      client = ::OpenAI::Client.new(access_token: @api_key)

      messages = if prompt.is_a?(Array)
                   prompt
                 else
                   [{ role: 'user', content: prompt }]
                 end

      response = client.chat(
        parameters: {
          model: CHAT_MODEL,
          messages: messages,
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

      Rails.logger.info("[AiClient::OpenAi] #{message}")
    end

    def log_error(message)
      return unless logging_enabled?

      Rails.logger.error("[AiClient::OpenAi] #{message}")
    end

    def logging_enabled?
      ENV['ENABLE_AI_CHAT_LOGS'] == 'true'
    end
  end
end
