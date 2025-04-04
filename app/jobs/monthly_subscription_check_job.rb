require 'mercadopago'

class MonthlySubscriptionCheckJob < ApplicationJob
  queue_as :default

  def perform
    users = User.where.not(subscription_id: nil) # Obtener usuarios con subscription_id
    mercado_pago = Mercadopago::SDK.new(ENV['MERCADO_PAGO_ACCESS_TOKEN'])

    users.each do |user|
      response = mercado_pago.preapproval.get(user.subscription_id)
      response_body = response[:response]

      if response_body['status'] != 'authorized'
        user.update(subscribed: false)
        Rails.logger.info "User id #{user.id} - subscription_id: #{user.subscription_id} unsubscribed due to status: #{response_body['status']}"
      else
        user.update(subscribed: true)
      end
    rescue StandardError => e
      Rails.logger.error "Error al procesar usuario #{user.id}: #{e.message}"
    end
    Rails.logger.info "Se han procesado #{users.count} usuarios para verificar su suscripción mensual."
  end
end
