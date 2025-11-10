class ApplicationController < ActionController::API
    include ActionController::Cookies
    
    # -------------------------- Session Authentication -------------------------- #
    def current_user_session
      @current_user_session ||= User.find_by(id: session[:user_id])
    end

    def authorize_session!
      unless current_user_session
        render json: { error: 'No session found' }, status: :unauthorized
      end
    end

    # ---------------------------- JWT Authentication ---------------------------- #
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

end