class ExpertController < ApplicationController
  before_action :authorize_jwt!
  before_action :require_expert_profile
  
  # GET /expert/queue
  def queue
    waiting_convos = Conversation.waiting.includes(:initiator, :messages)
    active_convos = Conversation.active
                                .where(assigned_expert_id: current_user_jwt.id)
                                .includes(:initiator, :messages, :assigned_expert)

    render json: {
      waitingConversations: waiting_convos.map {|conv| conversation_response(conv)},
      assignedConversations: active_convos.map {|conv| conversation_response(conv)}
    }
  end

  # POST /expert/conversations/:conversation_id/claim
  def claim
    conversation = Conversation.find_by(id: params[:conversation_id])
    unless conversation
      render json: {error: 'Conversation not found'}, status: :not_found
      return
    end
    if conversation.assigned_expert_id.present?
      render json: {error: "Conversation is already assigned to an expert"}, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      conversation.update!(assigned_expert: current_user_jwt, status: 'active')

      ExpertAssignment.create!(conversation: conversation, expert: current_user_jwt, status: 'active', assigned_at: Time.current)
    end

    render json: {success: true}, status: :ok
  end

  # POST /expert/conversations/:conversation_id/claim
  def unclaim
    conversation = Conversation.find_by(id: params[:conversation_id])
    unless conversation
      render json: {error: 'Conversation not found'}, status: :not_found
      return
    end

    if conversation.assigned_expert_id != current_user_jwt.id
      render json: {error: "You are not assigned to this conversation"}, status: :forbidden
      return
    end 
    ActiveRecord::Base.transaction do
      assignment = conversation.expert_assignments.find_by(expert_id: current_user_jwt.id, status: 'active')
      assignment&.update!(status: 'unassigned')
      conversation.update!(assigned_expert_id: nil, status: 'waiting')
    end

    render json: {success: true}, status: :ok
  end

  # GET /expert/profile
  def get_profile
    profile = ExpertProfile.find_by(user_id: current_user_jwt.id)
    render json: {
      id: profile.id,
      bio: profile.bio,
      knowledgeBaseLinks: profile.knowledge_base_links.presence || []
    }
  end
  
  # PUT /expert/profile
  def update_profile
    profile = ExpertProfile.find_by(user_id: current_user_jwt.id)
    if expert_profile_params.key?(:bio)
      profile.update(bio: expert_profile_params[:bio])
    end
    if expert_profile_params.key?(:knowledgeBaseLinks)
      profile.update(knowledge_base_links: expert_profile_params[:knowledgeBaseLinks])
    end

    if profile.save
      render json: {
        id: profile.id,
        bio: profile.bio,
        knowledgeBaseLinks: profile.knowledge_base_links.presence
      }
    else
      render json: { errors: current_user_jwt.expert_profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /expert/assignments/history
  def history
    assignments = ExpertAssignment.where(expert_id: current_user_jwt.id)
                                  .includes(conversation: :initiator)
                                  .order(assigned_at: :desc)
    render json: assignments.map { |assignment| assignment_response(assignment) }
  end
  


  private
  
  def require_expert_profile
    profile = current_user_jwt.expert_profile
    unless profile
      render json: { error: 'Expert profile not found' }, status: :not_found
    end
  end
  
  def expert_profile_params
    params.permit(:bio, knowledgeBaseLinks: [])
  end
  
  def expert_profile_response(profile)
    {
      id: profile.id,
      bio: profile.bio,
      knowledge_base_links: profile.knowledge_base_links || [],
      created_at: profile.created_at&.iso8601,
      updated_at: profile.updated_at&.iso8601
    }
  end

  def conversation_response(conversation)
    {
      id: conversation.id,
      title: conversation.title,
      status: conversation.status,
      questionerId: conversation.initiator_id,
      questionerUsername: conversation.initiator.username,
      assignedExpertId: conversation.assigned_expert_id,
      assignedExpertUsername: conversation.assigned_expert&.username,
      createdAt: conversation.created_at&.iso8601,
      updatedAt: conversation.updated_at&.iso8601,
      lastMessageAt: conversation.last_message_at&.iso8601
    }
  end

  def assignment_response(assignment)
    {
      id: assignment.id,
      conversationId: assignment.conversation_id,
      expertId: assignment.expert_id,
      status: assignment.status,
      assignedAt: assignment.assigned_at&.iso8601,
      resolvedAt: assignment.resolved_at&.iso8601,
      conversationTitle: assignment.conversation.title,
      questionerUsername: assignment.conversation.initiator.username
    }
  end
end