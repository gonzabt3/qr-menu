# app/controllers/api/ai/chats_controller.rb
module Api
  module Ai
    class ChatsController < ApplicationController
      # Skip authentication for AI chat endpoint
      skip_before_action :authorize_request, raise: false
      # Skip CSRF for API endpoint
      skip_before_action :verify_authenticity_token, raise: false

      before_action :check_feature_flag

      def create
        user_query = params[:user_query]

        if user_query.blank?
          return render json: { error: 'user_query is required' }, status: :bad_request
        end

        log_info("Received chat query: #{user_query}")
        start_time = Time.current

        # Generate embedding for user query
        query_embedding = AiClient.embed(user_query)
        query_embedding_encoded = Pgvector.encode(query_embedding)

        # Find similar products using vector similarity
        # Using cosine distance with pgvector
        similar_products = Product
          .where.not(embedding: nil)
          .order(Arel.sql("embedding <=> '#{query_embedding_encoded}'"))
          .limit(5)

        log_info("Found #{similar_products.count} similar products")

        # Build context for LLM
        context = build_context(similar_products)
        prompt = build_prompt(user_query, context)

        # Get completion from AI
        answer = AiClient.complete(prompt)

        # Build response with references
        references = similar_products.map do |product|
          {
            product_id: product.id,
            name: product.name,
            price: product.price,
            description: product.description&.truncate(100)
          }
        end

        duration = Time.current - start_time
        log_info("Chat request completed in #{duration.round(2)}s")

        render json: {
          answer: answer,
          references: references
        }, status: :ok
      rescue StandardError => e
        log_error("Error processing chat request: #{e.message}")
        log_error(e.backtrace.join("\n"))
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end

      private

      def check_feature_flag
        unless ENV['FEATURE_AI_CHAT_ENABLED'] == 'true'
          render json: { error: 'AI chat feature is not enabled' }, status: :forbidden
        end
      end

      def build_context(products)
        return "No hay productos disponibles en el menú." if products.empty?

        context_parts = products.map.with_index do |product, idx|
          parts = ["#{idx + 1}. #{product.name}"]
          parts << "Precio: $#{product.price}" if product.price
          parts << "Descripción: #{product.description}" if product.description.present?
          parts << "(Vegano)" if product.is_vegan
          parts << "(Apto para celíacos)" if product.is_celiac
          parts.join(" - ")
        end

        "Productos relevantes del menú:\n#{context_parts.join("\n")}"
      end

      def build_prompt(user_query, context)
        <<~PROMPT
          Contexto: #{context}

          Pregunta del cliente: #{user_query}

          Por favor, responde a la pregunta del cliente basándote en los productos del menú mencionados arriba. 
          Si los productos no son relevantes para la pregunta, indica amablemente que no tienes información específica pero ofrece alternativas si es posible.
          Menciona los nombres de los productos cuando sea apropiado.
        PROMPT
      end

      def log_info(message)
        Rails.logger.info("[Api::Ai::ChatsController] #{message}") if logging_enabled?
      end

      def log_error(message)
        Rails.logger.error("[Api::Ai::ChatsController] #{message}") if logging_enabled?
      end

      def logging_enabled?
        ENV['ENABLE_AI_CHAT_LOGS'] == 'true'
      end
    end
  end
end
