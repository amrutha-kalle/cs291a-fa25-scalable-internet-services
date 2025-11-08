class ExpertController < ApplicationController
  before_action :require_expert_profile
  
  # GET /expert/profile
  def get_profile
    render json: expert_profile_response(current_user.expert_profile)
  end
  
  # PUT /expert/profile
  def update_profile
    if current_user.expert_profile.update(expert_profile_params)
      render json: expert_profile_response(current_user.expert_profile)
    else
      render json: { errors: current_user.expert_profile.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def require_expert_profile
    unless current_user&.expert_profile
      render json: { error: 'Expert profile not found' }, status: :not_found
    end
  end
  
  def expert_profile_params
    params.permit(:bio, knowledge_base_links: [])
  end
  
  def expert_profile_response(profile)
    {
      id: profile.id.to_s,
      user_id: profile.user_id.to_s,
      bio: profile.bio,
      knowledge_base_links: profile.knowledge_base_links || [],
      created_at: profile.created_at&.iso8601,
      updated_at: profile.updated_at&.iso8601
    }
  end
end