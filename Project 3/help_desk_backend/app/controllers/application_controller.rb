class ApplicationController < ActionController::API
    include ActionController::Cookies

    before_action :authenticate_user

    private

    def authenticate_user
        return if current_user
        render json: {error: "Unauthorized"}, status: :unauthorized
    end

    def current_user_from_session
        return unless session[:user_id] 
        User.find_by(id: session[:user_id])
    end

    def current_user_from_jwt
        header = request.headers['Authorization']
        # puts "Authorization header: #{header}"  # Debug
        return unless header&.start_with?("Bearer ")

        token = header.split.last
        # puts "Token: #{token}"  # Debug
        decoded = JwtService.decode(token)
        # puts "Decoded: #{decoded.inspect}"  # Debug
        # puts "decoded id: #{decoded["user_id"]}"
        # puts "Decoded keys: #{decoded.keys}"
        # puts "decpded :user_id: #{decoded[:user_id]}"
        User.find_by(id: decoded[:user_id]) if decoded
    rescue => e
        puts "JWT Error: #{e.message}"  # Debug
        nil
    end

    def current_user
        @current_user ||= current_user_from_session || current_user_from_jwt
    end

    def require_session!
        @current_user = current_user_from_session
        render json: {error: "No session found"}, status: :unauthorized unless @current_user
    end
end