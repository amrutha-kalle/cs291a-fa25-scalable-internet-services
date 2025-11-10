class AuthController < ApplicationController

  # /auth/refresh and /auth/me need session authentication only
  before_action :authorize_session!, only: [:refresh, :me]

  # POST /auth/register
  def register
    user = User.new(username: params[:username], password: params[:password])
    if user.save
      # automatically create an expert profile when a user registers
      ExpertProfile.create(user: user, bio: "", knowledge_base_links: [])
      session[:user_id] = user.id
      token = JwtService.encode(user)
      render json: {
        user: user_json(user),
        token: token
      }, status: :created
    else
      render json: {errors: user.errors.full_messages}, status: :unprocessable_entity
    end

  end

  # POST /auth/login
  def login
    user = User.find_by(username: params[:username])
    if user&.authenticate(params[:password])
      user.update_column(:last_active_at, Time.current)
      session[:user_id] = user.id
      token = JwtService.encode(user)
      render json: {
        user: user_json(user),
        token: token
      }, status: :ok
    else
      render json: {error: 'Invalid username or password'}, status: :unauthorized
    end
  end

  # POST /auth/logout
  def logout
    reset_session
    render json: {
      message: "Logged out successfully"
    }, status: :ok
  end

  # POST /auth/refresh
  def refresh
    token = JwtService.encode(current_user_session)
    current_user_session.update_column(:last_active_at, Time.current)
    render json: {
      user: user_json(current_user_session),
      token: token
    }, status: :ok
  end

  # GET /auth/me
  def me
    if current_user_session
      render json: user_json(current_user_session)
    else
      render json: {error: 'No session found'}, status: :unauthorized
    end
  end
  
  private

  def user_params
    params.permit(:username, :password)
  end

  def user_json(user)
    {
      id: user.id,
      username: user.username,
      created_at: user.created_at.iso8601,
      last_active_at: user.last_active_at.iso8601
    }
  end

end
