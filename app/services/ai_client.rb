# app/services/ai_client.rb
module AiClient
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
        OpenAi.new
      else
        # Default to deepseak
        Deepseak.new
      end
    end
  end
end
