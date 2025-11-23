# app/services/ai_client/deepseak.rb
module AiClient
  class Deepseak
    BASE_URL = 'https://api.deepseek.com/v1'

    def initialize
      @api_key = ENV['DEEPSEAK_API_KEY']
      raise 'DEEPSEAK_API_KEY not configured' if @api_key.blank?
    end

    def embed(text)
      log_info("Generating embedding for text: #{text.truncate(100)}")

      response = HTTParty.post(
        "#{BASE_URL}/embeddings",
        headers: {
          'Authorization' => "Bearer #{@api_key}",
          'Content-Type' => 'application/json'
        },
        body: {
          model: 'deepseek-embedding',
          input: text
        }.to_json,
        timeout: 30
      )

      if response.success?
        embedding = response.parsed_response.dig('data', 0, 'embedding')
        log_info("Embedding generated successfully, dimensions: #{embedding&.length}")
        embedding
      else
        error_msg = "DeepSeek API error: #{response.code} - #{response.body}"
        log_error(error_msg)
        raise error_msg
      end
    rescue StandardError => e
      log_error("Error generating embedding: #{e.message}")
      raise
    end

    def complete(prompt, options = {})
      log_info("Generating completion with prompt: #{prompt.truncate(100)}")

      response = HTTParty.post(
        "#{BASE_URL}/chat/completions",
        headers: {
          'Authorization' => "Bearer #{@api_key}",
          'Content-Type' => 'application/json'
        },
        body: {
          model: options[:model] || 'deepseek-chat',
          messages: [
            { role: 'system', content: options[:system_message] || default_system_message },
            { role: 'user', content: prompt }
          ],
          temperature: options[:temperature] || 0.7,
          max_tokens: options[:max_tokens] || 500
        }.to_json,
        timeout: 60
      )

      if response.success?
        content = response.parsed_response.dig('choices', 0, 'message', 'content')
        log_info("Completion generated successfully, length: #{content&.length}")
        content
      else
        error_msg = "DeepSeek API error: #{response.code} - #{response.body}"
        log_error(error_msg)
        raise error_msg
      end
    rescue StandardError => e
      log_error("Error generating completion: #{e.message}")
      raise
    end

    private

    def default_system_message
      'Eres un asistente virtual de un restaurante. Tu tarea es ayudar a los clientes a encontrar platos que les gusten basándose en sus preferencias. Responde en español de manera amable y profesional.'
    end

    def log_info(message)
      Rails.logger.info("[AiClient::Deepseak] #{message}") if logging_enabled?
    end

    def log_error(message)
      Rails.logger.error("[AiClient::Deepseak] #{message}") if logging_enabled?
    end

    def logging_enabled?
      ENV['ENABLE_AI_CHAT_LOGS'] == 'true'
    end
  end
end
