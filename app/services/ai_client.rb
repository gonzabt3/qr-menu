# app/services/ai_client.rb
class AiClient
  class << self
    def embed(text)
      provider.embed(text)
    end

    def complete(prompt, options = {})
      provider.complete(prompt, options)
    end

    private

    def provider
      case ENV['AI_PROVIDER']&.downcase
      when 'openai'
        AiClient::OpenAi.new
      else
        # Default to deepseak
        AiClient::Deepseak.new
      end
    end
  end
end
