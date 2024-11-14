#frozen_string_literal: true

module Secured
  extend ActiveSupport::Concern

  REQUIRES_AUTHENTICATION = { message: 'Requires authentication' }.freeze
  BAD_CREDENTIALS = {
    message: 'Bad bad credentials'
  }.freeze
  MALFORMED_AUTHORIZATION_HEADER = {
    error: 'invalid_request',
    error_description: 'Authorization header value must follow this format: Bearer access-token',
    message: 'Bad credentials 2'
  }.freeze
  INSUFFICIENT_PERMISSIONS = {
    error: 'insufficient_permissions',
    error_description: 'The access token does not contain the required permissions',
    message: 'Permission denied'
  }.freeze

  def authorize
    byebug
    token = token_from_request

    return if performed?

    validation_response = Auth0Client.validate_token(token)
    print "asd"
    @decoded_token = validation_response.decoded_token
    print @decoded_token
    return unless (error = validation_response.error)

    render json: { message: error.message }, status: error.status
  end

  def validate_permissions(permissions)
    raise 'validate_permissions needs to be called with a block' unless block_given?
    return yield if @decoded_token.validate_permissions(permissions)

    render json: INSUFFICIENT_PERMISSIONS, status: :forbidden
  end

  private

  def token_from_request
    print request.headers['Authorization']
    authorization_header_elements = request.headers['Authorization']&.split
    scheme, token = authorization_header_elements
    return token
    print authorization_header_elements
    render json: REQUIRES_AUTHENTICATION, status: :unauthorized and return unless authorization_header_elements

    unless authorization_header_elements.length == 2
      render json: MALFORMED_AUTHORIZATION_HEADER,
             status: :unauthorized and return
    end

    scheme, token = authorization_header_elements
    print scheme.downcase != 'bearer'
    print 'gonza'
    render json: BAD_CREDENTIALS, status: :unauthorized and return if scheme.downcase != 'bearer'

    token
  end
end