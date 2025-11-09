class UpdatesController < ApplicationController
    skip_before_action :authenticate_user

  # GET /api/conversations/updates
  def conversations
    user = User.find_by(id: params[:userId])
    unless user
      render json: { error: 'User not found' }, status: :not_found
      return
    end

    conversations = user_conversations(user)
    
    if params[:since].present?
      since_time = Time.iso8601(params[:since])
      conversations = conversations.where('conversations.updated_at > ?', since_time)
    end

    render json: conversations.map { |conv| conversation_update_response(conv, user) }
  end

  # GET /api/messages/updates
  def messages
    user = User.find_by(id: params[:userId])
    
    unless user
      render json: { error: 'User not found' }, status: :not_found
      return
    end

    # Get conversations the user is involved in
    user_conversation_ids = Conversation.for_user(user).pluck(:id)
    
    messages = Message.where(conversation_id: user_conversation_ids)
                     .includes(:conversation, sender: :expert_profile)
                     .order(created_at: :asc)
    
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

    waiting_conversations = Conversation.waiting.includes(:initiator, :messages)
    assigned_conversations = Conversation.active.assigned_to(expert).includes(:initiator, :messages)

    if params[:since].present?
      since_time = Time.iso8601(params[:since])
      waiting_conversations = waiting_conversations.where('conversations.updated_at > ?', since_time)
      assigned_conversations = assigned_conversations.where('conversations.updated_at > ?', since_time)
    end

    render json: [{
      waitingConversations: waiting_conversations.map { |conv| conversation_update_response(conv, expert) },
      assignedConversations: assigned_conversations.map { |conv| conversation_update_response(conv, expert) }
    }]
  end

  private

  def user_conversations(user)
    Conversation.for_user(user)
               .includes(:initiator, :assigned_expert, :messages)
               .order(updated_at: :desc)
  end

  def conversation_update_response(conversation, current_user)
    {
      id: conversation.id.to_s,
      title: conversation.title,
      status: conversation.status,
      questionerId: conversation.initiator_id.to_s,
      questionerUsername: conversation.initiator.username,
      assignedExpertId: conversation.assigned_expert_id&.to_s,
      assignedExpertUsername: conversation.assigned_expert&.username,
      createdAt: conversation.created_at&.iso8601,
      updatedAt: conversation.updated_at&.iso8601,
      lastMessageAt: conversation.last_message_at&.iso8601,
      unreadCount: unread_count_for_conversation(conversation, current_user)
    }
  end

  def message_update_response(message)
    {
      id: message.id.to_s,
      conversationId: message.conversation_id.to_s,
      senderId: message.sender_id.to_s,
      senderUsername: message.sender.username,
      senderRole: message.sender_role,
      content: message.content,
      timestamp: message.created_at&.iso8601,
      isRead: message.is_read
    }
  end

  def unread_count_for_conversation(conversation, current_user)
    if current_user == conversation.initiator
      # Initiator sees unread expert messages
      conversation.messages.where(sender_role: 'expert', is_read: false).count
    elsif current_user == conversation.assigned_expert
      # Expert sees unread initiator messages  
      conversation.messages.where(sender_role: 'initiator', is_read: false).count
    else
      0
    end
  end

end
