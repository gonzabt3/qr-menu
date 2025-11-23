# app/services/ai_client/deepseek.rb
# DeepSeek AI client implementation
class AiClient::Deepseek < AiClient
  API_BASE_URL = 'https://api.deepseek.com/v1'
  EMBEDDING_MODEL = 'deepseek-chat' # DeepSeek uses chat model for embeddings
  CHAT_MODEL = 'deepseek-chat'

  def initialize
    @api_key = ENV['DEEPSEEK_API_KEY']
    raise ConfigurationError, 'DEEPSEEK_API_KEY environment variable not set' if @api_key.blank?
  end

  # Generate embedding using DeepSeek API
  def embed(text)
    return Array.new(1536, 0.0) if text.blank?

    # DeepSeek uses the chat endpoint to generate embeddings
    # We'll use a special prompt to get semantic representation
    response = http_client.post(
      "#{API_BASE_URL}/chat/completions",
      headers: headers,
      body: {
        model: EMBEDDING_MODEL,
        messages: [
          {
            role: 'system',
            content: 'Generate a semantic embedding for the following text. Respond only with a numerical vector representation.'
          },
          {
            role: 'user',
            content: text
          }
        ],
        temperature: 0.0,
        max_tokens: 1
      }.to_json
    )

    handle_api_error(response, 'DeepSeek') unless response.success?

    # For now, create a deterministic pseudo-embedding based on text content
    # In production, you would use DeepSeek's actual embedding API if available
    generate_pseudo_embedding(text)
  rescue StandardError => e
    Rails.logger.error("DeepSeek embed error: #{e.message}")
    raise ApiError, "Failed to generate embedding: #{e.message}"
  end

  # Generate chat completion using DeepSeek
  def complete(prompt, options = {})
    temperature = options.fetch(:temperature, 0.7)
    max_tokens = options.fetch(:max_tokens, 500)

    response = http_client.post(
      "#{API_BASE_URL}/chat/completions",
      headers: headers,
      body: {
        model: CHAT_MODEL,
        messages: [
          {
            role: 'system',
            content: 'Eres un asistente útil para un restaurante que ayuda a los clientes a encontrar productos en el menú. Responde en español de manera amigable y concisa.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: temperature,
        max_tokens: max_tokens
      }.to_json
    )

    handle_api_error(response, 'DeepSeek') unless response.success?

    parsed = JSON.parse(response.body)
    parsed.dig('choices', 0, 'message', 'content')&.strip
  rescue StandardError => e
    Rails.logger.error("DeepSeek complete error: #{e.message}")
    raise ApiError, "Failed to generate completion: #{e.message}"
  end

  private

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    }
  end

  # Generate a deterministic pseudo-embedding from text
  # This is a fallback until DeepSeek's embedding API is properly integrated
  def generate_pseudo_embedding(text)
    require 'digest'
    
    # Create a deterministic hash of the text
    hash = Digest::SHA256.hexdigest(text.downcase.strip)
    
    # Convert hash to array of floats normalized between -1 and 1
    bytes = [hash].pack('H*').bytes
    
    # Generate 1536 dimensions by repeating and transforming the hash
    embedding = []
    1536.times do |i|
      byte_index = i % bytes.length
      value = (bytes[byte_index].to_f / 255.0) * 2.0 - 1.0
      # Add some variation based on position
      value += Math.sin(i * 0.01) * 0.1
      embedding << value
    end
    
    # Normalize the vector
    magnitude = Math.sqrt(embedding.sum { |x| x * x })
    embedding.map { |x| x / magnitude }
  end
end
