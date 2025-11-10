class ConversationsController < ApplicationController
    # GET /conversations
    before_action :authorize_jwt!
    
    def index
        conversations = Conversation.for_user(current_user_jwt)
                                    .includes(:initiator, :assigned_expert)
                                    .order(created_at: :desc)
        render json: conversations.map{|conv| conversation_response(conv)}
    end

    # GET /conversations/:id
    def show
        begin
          conversation = Conversation.includes(:initiator, :assigned_expert).find(params[:id])
        rescue ActiveRecord::RecordNotFound
            render json: {error: 'Conversation not found'}, status: :not_found
            return
        end
        
        unless conversation.initiator == current_user_jwt || conversation.assigned_expert == current_user_jwt
            render json: {error: 'Conversation not found'}, status: :not_found
            return
        end
        render json: conversation_response(conversation)
    end

    # POST /conversations
    def create
        conversation = Conversation.new(conversation_params)
        conversation.initiator = current_user_jwt
        conversation.last_message_at = Time.current
        
        if conversation.save
            render json: conversation_response(conversation), status: :created
        else
            render json: {errors: conversation.errors.full_messages}, status: :unprocessable_entity
        end
    end

    
    private
  
    def conversation_params
        params.permit(:title)
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
end
