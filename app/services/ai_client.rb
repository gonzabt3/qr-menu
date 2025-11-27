# app/services/ai_client.rb
# Base AI client that routes to the appropriate provider (DeepSeek or OpenAI)
class AiClient
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ApiError < Error; end

  # Factory method to get the appropriate AI client based on configuration
  def self.instance
    provider = ENV.fetch('AI_PROVIDER', 'deepseek').downcase
    
    case provider
    when 'deepseek'
      AiClient::Deepseek.new
    when 'openai'
      AiClient::Openai.new
    else
      raise ConfigurationError, "Unknown AI_PROVIDER: #{provider}. Use 'deepseek' or 'openai'"
    end
  end

  # Generate embedding vector for text
  # @param text [String] The text to embed
  # @return [Array<Float>] Vector embedding (1536 dimensions)
  def embed(text)
    raise NotImplementedError, 'Subclasses must implement #embed'
  end

  # Generate text completion using the AI model
  # @param prompt [String] The prompt to send to the model
  # @param options [Hash] Additional options (temperature, max_tokens, etc.)
  # @return [String] Generated text response
  def complete(prompt, options = {})
    raise NotImplementedError, 'Subclasses must implement #complete'
  end

  protected

  def http_client
    @http_client ||= HTTParty
  end

  def handle_api_error(response, provider_name)
    raise ApiError, "#{provider_name} API error (#{response.code}): #{response.body}"
  end
end
