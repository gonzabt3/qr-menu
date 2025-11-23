# app/controllers/chat_controller.rb
# Controller for AI-powered chat functionality using RAG (Retrieval Augmented Generation)
class ChatController < ApplicationController
  skip_before_action :authorize, only: [:create], if: -> { defined?(:authorize) }

  # POST /chat
  # Request body: { user_query: "string", menu_id: integer, locale: "es" (optional) }
  def create
    user_query = params[:user_query]&.strip
    menu_id = params[:menu_id]
    locale = params[:locale] || 'es'
    top_k = params[:top_k]&.to_i || 5

    # Validate input
    if user_query.blank?
      render json: { error: 'user_query is required' }, status: :bad_request
      return
    end

    if menu_id.blank?
      render json: { error: 'menu_id is required' }, status: :bad_request
      return
    end

    # Verify menu exists
    menu = Menu.find_by(id: menu_id)
    unless menu
      render json: { error: 'Menu not found' }, status: :not_found
      return
    end

    begin
      # Generate embedding for user query
      ai_client = AiClient.instance
      query_embedding = ai_client.embed(user_query)

      # Find similar products using vector similarity search
      # Filter by menu's products
      section_ids = menu.sections.pluck(:id)
      similar_products = find_similar_products(query_embedding, section_ids, top_k)

      if similar_products.empty?
        # No products found, return a helpful message
        render json: {
          answer: 'Lo siento, no encontré productos relacionados con tu consulta en este menú. ¿Puedes reformular tu pregunta?',
          references: []
        }
        return
      end

      # Build RAG prompt with context
      prompt = build_rag_prompt(user_query, similar_products, locale)

      # Generate response using LLM
      answer = ai_client.complete(prompt, temperature: 0.7, max_tokens: 500)

      # Format references
      references = similar_products.map do |product|
        {
          product_id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          similarity_score: product.similarity_score&.round(4),
          is_vegan: product.is_vegan,
          is_celiac: product.is_celiac
        }
      end

      render json: {
        answer: answer,
        references: references
      }, status: :ok

    rescue AiClient::ConfigurationError => e
      Rails.logger.error("AI configuration error: #{e.message}")
      render json: { error: 'AI service is not properly configured' }, status: :service_unavailable

    rescue AiClient::ApiError => e
      Rails.logger.error("AI API error: #{e.message}")
      render json: { error: 'AI service temporarily unavailable' }, status: :service_unavailable

    rescue StandardError => e
      Rails.logger.error("Chat error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
    end
  end

  private

  # Find products similar to query embedding using cosine distance
  def find_similar_products(query_embedding, section_ids, limit = 5)
    return [] if query_embedding.blank?

    # Convert embedding array to PostgreSQL vector format
    embedding_str = "[#{query_embedding.join(',')}]"

    # Use pgvector's cosine distance operator (<=>)
    # Lower distance means more similar
    Product.joins(:section)
           .where(sections: { id: section_ids })
           .where.not(embedding: nil)
           .select("products.*, (embedding <=> '#{embedding_str}') as similarity_score")
           .order('similarity_score ASC')
           .limit(limit)
  end

  # Build prompt for RAG with retrieved context
  def build_rag_prompt(query, products, locale)
    # System context
    context = "Eres un asistente útil de un restaurante. Un cliente te hace una pregunta sobre el menú.\n\n"
    context += "Productos relevantes del menú:\n\n"

    # Add product information
    products.each_with_index do |product, index|
      context += "#{index + 1}. #{product.name}"
      context += " - $#{product.price}" if product.price
      context += "\n   #{product.description}" if product.description.present?
      
      attributes = []
      attributes << "vegano" if product.is_vegan
      attributes << "apto para celíacos" if product.is_celiac
      context += "\n   (#{attributes.join(', ')})" if attributes.any?
      
      context += "\n\n"
    end

    context += "\nPregunta del cliente: #{query}\n\n"
    context += "Instrucciones:\n"
    context += "- Responde en español de manera amigable y natural\n"
    context += "- Usa la información de los productos anteriores para responder\n"
    context += "- Sé conciso pero útil\n"
    context += "- Si los productos no son exactamente lo que busca, sugiere alternativas del menú\n"
    context += "- Menciona características especiales (vegano, celíaco) si son relevantes\n"
    context += "- No inventes información que no esté en los productos listados\n\n"
    context += "Respuesta:"

    context
  end
end
