class ApplicationController < ActionController::API
    include ActionController::Cookies

    def current_user_session
    @current_user_session ||= User.find_by(id: session[:user_id])
  end

  def authorize_session!
    unless current_user_session
      render json: { error: 'No session found' }, status: :unauthorized
    end
  end

  # ----- JWT auth -----
  def current_user_jwt
    token = request.headers['Authorization']&.split(' ')&.last
    return nil unless token

    begin
        decoded_token = JwtService.decode(token)
        return nil unless decoded_token
        @current_user_jwt ||= User.find_by(id: decoded_token[:user_id])
    rescue JWT::DecodeError => e
        Rails.logger.error "JWT decode error: #{e.message}"
        nil
    end
  end

  def authorize_jwt!
    unless current_user_jwt
      render json: { error: 'Not authorized' }, status: :unauthorized
    end
  end

    # before_action :authenticate_user

    # def authenticate_user
    #     Rails.logger.debug "Session: #{session[:user_id].inspect}, Auth header: #{request.headers['Authorization'].inspect}"
    #     return if current_user
    #     render json: {error: "Unauthorized"}, status: :unauthorized
    # end

    # def current_user_from_session
    #     return unless session[:user_id] 
    #     User.find_by(id: session[:user_id])
    # end

    # def current_user_from_jwt
    #     token = request.headers['Authorization']&.split(' ')&.last
    #     return nil unless token
    #     begin
    #         decoded_token = JwtService.decode(token)
    #         return nil unless decoded_token
    #         User.find_by(id: decoded_token[:user_id])
    #     rescue JWT::DecodeError
    #         nil
    #     end
    # end
    # def current_user_from_jwt
    #     header = request.headers['Authorization']
    #     # puts "Authorization header: #{header}"  # Debug
    #     return unless header&.start_with?("Bearer ")

    #     token = header.split.last
    #     # puts "Token: #{token}"  # Debug
    #     decoded = JwtService.decode(token)
    #     # puts "Decoded: #{decoded.inspect}"  # Debug
    #     # puts "decoded id: #{decoded["user_id"]}"
    #     # puts "Decoded keys: #{decoded.keys}"
    #     # puts "decpded :user_id: #{decoded[:user_id]}"
    #     User.find_by(id: decoded[:user_id]) if decoded
    # rescue => e
    #     puts "JWT Error: #{e.message}"  # Debug
    #     nil
    # end

    # def current_user
    #     @current_user ||= current_user_from_session || current_user_from_jwt
    # end

    # def require_session!
    #     @current_user = current_user_from_session
    #     render json: {error: "No session found"}, status: :unauthorized unless @current_user
    # end
end