class MessagesController < ApplicationController

  # GET /conversations/:conversation_id/messages
  def index
    conversation = Conversation.find_by(id: params[:conversation_id])
    unless conversation
      render json: {error: "Conversation not found"}, status: :not_found
      return
    end
    # unless authorized_for_conversation?(conversation)
    #   render json: {error: "Not authorized"}, status: :forbidden
    #   return
    # end
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
    unless authorized_for_conversation?(conversation)
      render json: {error: "Not authorized"}, status: :forbidden
      return
    end

    
    # update status if waiting and expert is assigned
    if conversation.status == "waiting" && conversation.assigned_expert
      conversation.update(status: "active")
    end

    current_role = determine_sender_role(conversation)

    message = Message.new(conversation: conversation, sender: current_user, sender_role: current_role, content: params[:content])

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
    unless authorized_for_message?(message)
      render json: {error: 'Not authorized'}, status: :forbidden
      return
    end
    if message.sender == current_user
      render json: {error: 'Cannot mark your own messages as read'}, status: :forbidden
      return
    end
    conversation = message.conversation
    unless conversation
      render json: {error: "Conversation not found"}, status: :not_found
      return
    end
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
    conversation.initiator == current_user || conversation.assigned_expert == current_user
  end

  def authorized_for_message?(message)
    conversation = message.conversation
    conversation.initiator == current_user || conversation.assigned_expert == current_user
  end

  def determine_sender_role(conversation)
    current_user == conversation.initiator ? 'initiator' : 'expert'
  end

  def message_response(message)
    {
      id: message.id.to_s,
      conversationId: message.conversation_id.to_s,
      senderId: message.sender_id.to_s,
      senderUsername: message.sender.username,
      senderRole: message.sender_role,
      content: message.content,
      timestamp: message.created_at.iso8601,
      isRead: message.is_read
    }
  end
end
