class ApplicationController < ActionController::API
    include ActionController::Cookies

    before_action :authenticate_user

    private

    def authenticate_user
        @current_user = current_user
    end

    def current_user_from_session
        return unless session[:user_id] 
        User.find_by(id: session[:user_id])
    end

    def current_user_from_jwt
        header = request.headers['Authorization']
        return unless header&.start_with?("Bearer ")

        token = header.split.last
        decoded = JwtService.decode(token)
        User.find_by(id: decoded["user_id"]) if decoded
    rescue
        nil
    end

    def current_user
        current_user_from_session || current_user_from_jwt
    end

    def require_session!
        @current_user = current_user_from_session
        render json: {error: "No session found"}, status: :unauthorized unless @current_user
    end
end