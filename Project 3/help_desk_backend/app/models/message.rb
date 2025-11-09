class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :content, presence: true
  validates :sender_role, presence: true, inclusion: {in: %w[initiator expert]}
  validates :is_read, inclusion: {in: [true, false]}

  after_create :update_conversation_last_message

  scope :unread, -> {where(is_read: false)}
  scope :by_conversation, ->(conversation_id) {where(conversation_id: conversation_id)}
  scope :ordered, -> {order(created_at: :asc)}


  def mark_as_read!
    update!(is_read: true)
  end


  private
  
  def update_conversation_last_message
    conversation.update_last_message_at!
  end

end
