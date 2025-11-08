class Conversation < ApplicationRecord
  belongs_to :initiator, class_name: "User"
  belongs_to :assigned_expert, class_name: "User", optional: true

  # TODO: add back once messages have been implemented
  # has_many :messages, dependent: :destroy

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

  def assigned_expert!(expert)
    update!(assigned_expert: expert, status: 'active')
  end

  def unassign_expert!
    update!(assigned_expert: nil, status: "waiting")
  end


  private
  def set_defualt_status
    self.status ||= "waiting"
  end

end
