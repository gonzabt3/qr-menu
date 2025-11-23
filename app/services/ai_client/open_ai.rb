# app/services/ai_client/open_ai.rb
module AiClient
  class OpenAi
    def initialize
      @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
      raise 'OPENAI_API_KEY not configured' if ENV['OPENAI_API_KEY'].blank?
    end

    def embed(text)
      log_info("Generating embedding for text: #{text.truncate(100)}")

      response = @client.embeddings(
        parameters: {
          model: 'text-embedding-ada-002',
          input: text
        }
      )

      embedding = response.dig('data', 0, 'embedding')
      log_info("Embedding generated successfully, dimensions: #{embedding&.length}")
      embedding
    rescue StandardError => e
      log_error("Error generating embedding: #{e.message}")
      raise
    end

    def complete(prompt, options = {})
      log_info("Generating completion with prompt: #{prompt.truncate(100)}")

      response = @client.chat(
        parameters: {
          model: options[:model] || 'gpt-3.5-turbo',
          messages: [
            { role: 'system', content: options[:system_message] || default_system_message },
            { role: 'user', content: prompt }
          ],
          temperature: options[:temperature] || 0.7,
          max_tokens: options[:max_tokens] || 500
        }
      )

      content = response.dig('choices', 0, 'message', 'content')
      log_info("Completion generated successfully, length: #{content&.length}")
      content
    rescue StandardError => e
      log_error("Error generating completion: #{e.message}")
      raise
    end

    private

    def default_system_message
      'Eres un asistente virtual de un restaurante. Tu tarea es ayudar a los clientes a encontrar platos que les gusten basándose en sus preferencias. Responde en español de manera amable y profesional.'
    end

    def log_info(message)
      Rails.logger.info("[AiClient::OpenAI] #{message}") if logging_enabled?
    end

    def log_error(message)
      Rails.logger.error("[AiClient::OpenAI] #{message}") if logging_enabled?
    end

    def logging_enabled?
      ENV['ENABLE_AI_CHAT_LOGS'] == 'true'
    end
  end
end
