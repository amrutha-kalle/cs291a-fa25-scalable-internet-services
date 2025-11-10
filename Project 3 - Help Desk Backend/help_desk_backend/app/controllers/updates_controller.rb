class UpdatesController < ApplicationController
    before_action :authorize_jwt!

  # GET /api/conversations/updates
  def conversations
    since_time = parse_since(params[:since])
    conversations = Conversation
      .where("initiator_id = :user_id OR assigned_expert_id = :user_id", user_id: params[:userId])
      .where("updated_at > ?", since_time)
      .includes(:initiator, :assigned_expert, :messages)

    render json: conversations.map { |conv| conversation_update_response(conv) }
  end

  # GET /api/messages/updates
  def messages
    user = User.find_by(id: params[:userId])
    unless user
      render json: { error: 'User not found' }, status: :not_found
      return
    end

    user_conversation_ids = Conversation.for_user(user).pluck(:id)
    messages = Message.where(conversation_id: user_conversation_ids).includes(:conversation, sender: :expert_profile).order(created_at: :asc)
    if params[:since].present?
      since_time = Time.iso8601(params[:since])
      messages = messages.where('messages.created_at > ?', since_time)
    end

    render json: messages.map { |msg| message_update_response(msg) }
  end

  # GET /api/expert-queue/updates
  def expert_queue
    expert = User.find_by(id: params[:expertId])
    
    unless expert&.expert_profile
      render json: { error: 'Expert not found' }, status: :not_found
      return
    end

    waiting_conversations = Conversation.waiting.includes(:initiator).where.not(initiator_id: expert.id).order(created_at: :desc).map{|conv| conversation_update_response(conv)}
    assigned_conversations = Conversation.active.assigned_to(expert).includes(:initiator, :messages).order(updated_at: :desc).map{|conv| conversation_update_response(conv)}

    render json: [{
      waitingConversations: waiting_conversations,
      assignedConversations: assigned_conversations
    }]
  end

  private

  def user_conversations(user)
    Conversation.for_user(user)
               .includes(:initiator, :assigned_expert, :messages)
               .order(updated_at: :desc)
  end

  def conversation_update_response(conversation)
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
      lastMessageAt: conversation.last_message_at&.iso8601,
      unreadCount: 0
    }
  end

  def message_update_response(message)
    {
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      senderUsername: message.sender.username,
      senderRole: message.sender_role,
      content: message.content,
      timestamp: message.created_at&.iso8601,
      isRead: message.is_read
    }
  end

  def unread_count_for_conversation(conversation, current_user_jwt)
    if current_user_jwt == conversation.initiator
      conversation.messages.where(sender_role: 'expert', is_read: false).count
    elsif current_user_jwt == conversation.assigned_expert
      conversation.messages.where(sender_role: 'initiator', is_read: false).count
    else
      0
    end
  end

  def parse_since(since_param)
    since_param.present? ? DateTime.iso8601(since_param) : Time.at(0)
  rescue ArgumentError
    Time.at(0)
  end

end
