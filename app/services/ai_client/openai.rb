# app/services/ai_client/openai.rb
# OpenAI AI client implementation
class AiClient::Openai < AiClient
  API_BASE_URL = 'https://api.openai.com/v1'
  EMBEDDING_MODEL = 'text-embedding-ada-002'
  CHAT_MODEL = 'gpt-3.5-turbo'

  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    raise ConfigurationError, 'OPENAI_API_KEY environment variable not set' if @api_key.blank?
  end

  # Generate embedding using OpenAI API
  def embed(text)
    return Array.new(1536, 0.0) if text.blank?

    response = http_client.post(
      "#{API_BASE_URL}/embeddings",
      headers: headers,
      body: {
        model: EMBEDDING_MODEL,
        input: text
      }.to_json
    )

    handle_api_error(response, 'OpenAI') unless response.success?

    parsed = JSON.parse(response.body)
    parsed.dig('data', 0, 'embedding')
  rescue StandardError => e
    Rails.logger.error("OpenAI embed error: #{e.message}")
    raise ApiError, "Failed to generate embedding: #{e.message}"
  end

  # Generate chat completion using OpenAI
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

    handle_api_error(response, 'OpenAI') unless response.success?

    parsed = JSON.parse(response.body)
    parsed.dig('choices', 0, 'message', 'content')&.strip
  rescue StandardError => e
    Rails.logger.error("OpenAI complete error: #{e.message}")
    raise ApiError, "Failed to generate completion: #{e.message}"
  end

  private

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    }
  end
end
