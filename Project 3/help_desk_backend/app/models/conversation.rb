class Conversation < ApplicationRecord
  belongs_to :initiator, class_name: "User"
  belongs_to :assigned_expert, class_name: "User", optional: true
  
  has_many :expert_assignments, dependent: :destroy
  has_many :messages, dependent: :destroy

  # validations
  validates :title, presence: true
  validates :status, inclusion: {in: %w[waiting active resolved]}

  before_validation :set_defualt_status, on: :create
  
  scope :for_user, ->(user) {
    where("initiator_id = ? OR assigned_expert_id = ?", user.id, user.id)
  }
  scope :waiting, -> {where(status: "waiting")}
  scope :active, -> {where(status: "active")}
  scope :resolved, -> {where(status: "resolved")}
  scope :assigned_to, ->(expert) {where(assigned_expert_id: expert.id)}
  scope :unassigned, -> {where(assigned_expert_id: nil)}

  def update_last_message_at!
    update(last_message_at: Time.current)
  end

  # def assign_expert!(expert)
  #   expert_assignments.active.update_all(status: 'unassigned')
  #   expert_assignments.create!(expert: expert, status: 'active', assigned_at: Time.current)
  #   update!(assigned_expert: expert, status: 'active')
  # end

  # def unassign_expert!
  #   update!(assigned_expert: nil, status: "waiting")
  # end
  # end

  def unread_messages_count_for(user)
    if user == initiator
      messages.where(sender_role: 'expert', is_read: false).count
    elsif user == assigned_expert
      messages.where(sender_role: 'initiator', is_read: false).count
    else
      0
    end
  end


  private
  def set_defualt_status
    self.status ||= "waiting"
  end

end
