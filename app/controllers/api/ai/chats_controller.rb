# frozen_string_literal: true

module Api
  module Ai
    # Controller for AI-powered chat interactions
    class ChatsController < ApplicationController
      skip_before_action :authorize

      before_action :check_feature_enabled

      # POST /ai/chat
      # Request body: { user_query: string, session_id: string (optional), locale: string (optional) }
      # Response: { answer: string, references: [{ product_id, name, score }] }
      def create
        user_query = params[:user_query]
        session_id = params[:session_id] || SecureRandom.uuid
        locale = params[:locale] || 'es'

        if user_query.blank?
          render json: { error: 'user_query is required' }, status: :bad_request
          return
        end

        start_time = Time.current
        log_info("Processing chat query: #{user_query[0..50]}... (session: #{session_id})")

        # Generate embedding for the user query
        query_embedding = AiClient.embed(user_query)

        # Find similar products using vector similarity search
        # Using cosine distance operator (<->) for similarity
        similar_products = find_similar_products(query_embedding, limit: 5)

        log_info("Found #{similar_products.count} similar products")

        # Build context from similar products
        context = build_context(similar_products)

        # Build prompt for LLM
        prompt = build_prompt(user_query, context, locale)

        # Generate answer using LLM
        answer = AiClient.complete(prompt, temperature: 0.7, max_tokens: 500)

        # Prepare references
        references = similar_products.map do |product|
          {
            product_id: product.id,
            name: product.name,
            score: product.similarity_score
          }
        end

        elapsed_time = Time.current - start_time
        log_info("Generated response in #{elapsed_time.round(2)}s")

        # Log metadata if enabled
        log_metadata(session_id, user_query, references, elapsed_time) if logging_enabled?

        render json: {
          answer: answer,
          references: references,
          session_id: session_id
        }, status: :ok
      rescue StandardError => e
        log_error("Error processing chat: #{e.message}")
        log_error(e.backtrace.join("\n")) if logging_enabled?

        render json: {
          error: 'An error occurred while processing your request',
          details: Rails.env.development? ? e.message : nil
        }, status: :internal_server_error
      end

      private

      def check_feature_enabled
        return if ENV['FEATURE_AI_CHAT_ENABLED'] == 'true'

        render json: { error: 'AI chat feature is not enabled' }, status: :not_found
      end

      # Find products similar to the query embedding
      def find_similar_products(query_embedding, limit: 5)
        # Use pgvector's cosine distance operator
        # Returns products ordered by similarity (lower distance = more similar)
        # Convert array embedding to pgvector format: [1,2,3]
        embedding_str = if query_embedding.is_a?(Array)
                          "[#{query_embedding.map { |v| ActiveRecord::Base.connection.quote(v) }.join(',')}]"
                        else
                          ActiveRecord::Base.connection.quote(query_embedding)
                        end

        # Use parameterized query with Arel to prevent SQL injection
        Product.select(
          'products.*',
          Arel.sql("embedding <-> '#{embedding_str}' AS similarity_score")
        )
               .where.not(embedding: nil)
               .order(Arel.sql('similarity_score ASC'))
               .limit(limit)
      end

      def build_context(products)
        return 'No hay productos disponibles.' if products.empty?

        context = "Productos disponibles en el menú:\n\n"
        products.each_with_index do |product, index|
          context += "#{index + 1}. #{product.name}"
          context += " - #{product.description}" if product.description.present?
          context += " - Precio: $#{product.price}"

          dietary = []
          dietary << 'vegano' if product.is_vegan
          dietary << 'apto para celíacos' if product.is_celiac
          context += " (#{dietary.join(', ')})" if dietary.any?

          context += "\n"
        end

        context
      end

      def build_prompt(user_query, context, locale)
        system_message = if locale == 'es'
                           'Eres un asistente virtual amable y servicial de un restaurante. ' \
                           'Tu trabajo es ayudar a los clientes a elegir platos del menú basándote ' \
                           'en la información proporcionada. Responde de manera concisa, amigable y ' \
                           'en español. Si la pregunta no está relacionada con el menú, menciona ' \
                           'amablemente que solo puedes ayudar con consultas sobre el menú.'
                         else
                           'You are a friendly and helpful virtual assistant for a restaurant. ' \
                           'Your job is to help customers choose dishes from the menu based on ' \
                           'the provided information. Respond concisely and friendly. If the ' \
                           'question is not related to the menu, politely mention that you can ' \
                           'only help with menu-related queries.'
                         end

        [
          { role: 'system', content: system_message },
          { role: 'user', content: "#{context}\n\nPregunta del cliente: #{user_query}" }
        ]
      end

      def log_metadata(session_id, query, references, elapsed_time)
        metadata = {
          session_id: session_id,
          query_hash: Digest::SHA256.hexdigest(query),
          query_length: query.length,
          references_count: references.count,
          elapsed_time: elapsed_time.round(3),
          timestamp: Time.current.iso8601
        }

        Rails.logger.info("[AiChat] Metadata: #{metadata.to_json}")
      end

      def log_info(message)
        return unless logging_enabled?

        Rails.logger.info("[Api::Ai::ChatsController] #{message}")
      end

      def log_error(message)
        return unless logging_enabled?

        Rails.logger.error("[Api::Ai::ChatsController] #{message}")
      end

      def logging_enabled?
        ENV['ENABLE_AI_CHAT_LOGS'] == 'true'
      end
    end
  end
end
