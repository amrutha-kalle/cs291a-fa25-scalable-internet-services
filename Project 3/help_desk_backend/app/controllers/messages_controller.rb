class MessagesController < ApplicationController
  before_action :authorize_jwt!

  # GET /conversations/:conversation_id/messages
  def index
    conversation = Conversation.find_by(id: params[:conversation_id])
    
    unless conversation
      render json: {error: "Conversation not found"}, status: :not_found
      return
    end
    conversation.reload
    unless authorized_for_conversation?(conversation)
      render json: {error: "Not authorized"}, status: :forbidden
      return
    end
    messages = conversation.messages.ordered.includes(:sender)
    render json: messages.map{|message| message_response(message)}
  end

  # POST /messages
  def create
    conversation = Conversation.find_by(id: params[:conversationId])
    unless conversation
      render json: {error: "Conversation not found"}, status: :not_found
      return
    end
    conversation.reload
    unless authorized_for_conversation?(conversation)
      render json: {error: "Not authorized"}, status: :forbidden
      return
    end

    
    # update status if waiting and expert is assigned
    if conversation.status == "waiting" && conversation.assigned_expert
      conversation.update(status: "active")
    end

    current_role = determine_sender_role(conversation)

    message = Message.new(conversation: conversation, sender: current_user_jwt, sender_role: current_role, content: params[:content])

    if message.save
      render json: message_response(message), status: :created
    else
      render json: {errors: messages.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PUT /messages/:id/read
  def mark_as_read
    message = Message.find_by(id: params[:id])
    unless message
      render json: {error: "Message not found"}, status: :not_found
      return
    end
    message.reload
    unless authorized_for_message?(message)
      render json: {error: 'Not authorized'}, status: :forbidden
      return
    end
    if message.sender == current_user_jwt
      render json: {error: 'Cannot mark your own messages as read'}, status: :forbidden
      return
    end
    conversation = message.conversation
    unless conversation
      render json: {error: "Conversation not found"}, status: :not_found
      return
    end
    conversation.reload
    unless authorized_for_conversation?(conversation)
      render json: {error: "No authorized"}, status: forbidden
      return
    end

    if message.mark_as_read!
      render json: {success: true}
    else
      render json: {errors: message.errors.full_messages}, status: :unprocessable_entity
    end

  end


  private

  def message_params
    params.permit(:content, :conversationId)
  end

  def authorized_for_conversation?(conversation)
    Rails.logger.info "Current_user id: #{current_user_jwt.id}"
    Rails.logger.info "convo init id: #{conversation.initiator.id}"
    if conversation.status == 'waiting'
      Rails.logger.info "convo has no expert"
    else
      Rails.logger.info "convo expert id: #{conversation.assigned_expert.id}"
    end
    conversation.initiator == current_user_jwt || conversation.assigned_expert == current_user_jwt
  end

  def authorized_for_message?(message)
    conversation = message.conversation
    conversation.initiator == current_user_jwt || conversation.assigned_expert == current_user_jwt
  end

  def determine_sender_role(conversation)
    current_user_jwt == conversation.initiator ? 'initiator' : 'expert'
  end

  def message_response(message)
    {
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      senderUsername: message.sender.username,
      senderRole: message.sender_role,
      content: message.content,
      timestamp: message.created_at.iso8601,
      isRead: message.is_read
    }
  end
end
