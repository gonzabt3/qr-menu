class AiChatController < ApplicationController
  before_action :authorize

  # POST /ai_chat/prompt
  def prompt
    user_message = params[:message]

    # Aquí deberías integrar tu proveedor de IA (por ejemplo, OpenAI, Azure, etc.)
    # Por ahora, respondemos con un mensaje simulado.
    ai_response = <<~REACT
      <div style={{ padding: 20, background: '#F6E05E', borderRadius: 8 }}>
        <h2 style={{ color: '#ED8936' }}>¡Hola desde la IA!</h2>
        <p>Este es un ejemplo de código React generado dinámicamente.</p>
        <ul>
          <li>Vegano 🌱</li>
          <li>Apto Celíacos 🚫🌾</li>
        </ul>
      </div>
    REACT
    render json: { response: ai_response }
  end
end
