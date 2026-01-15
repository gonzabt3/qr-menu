# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In production, CORS_ALLOWED_ORIGINS must be set explicitly
    # In development, default to localhost
    if Rails.env.production?
      # Require CORS_ALLOWED_ORIGINS in production for security
      cors_origins = ENV.fetch('CORS_ALLOWED_ORIGINS') do
        raise 'CORS_ALLOWED_ORIGINS environment variable must be set in production'
      end
      origins(*cors_origins.split(',').map(&:strip))
    else
      # Development default
      cors_origins = ENV.fetch('CORS_ALLOWED_ORIGINS', 'http://localhost:3001')
      origins(*cors_origins.split(',').map(&:strip))
    end

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end
end
