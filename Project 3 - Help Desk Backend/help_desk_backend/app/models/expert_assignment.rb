class ExpertAssignment < ApplicationRecord
  belongs_to :conversation
  belongs_to :expert, class_name: 'User'

  validates :conversation_id, presence: true
  validates :expert_id, presence: true
  validates :status, presence: true, inclusion: { in: %w[active resolved unassigned] }
  validates :assigned_at, presence: true

  before_validation :set_assigned_at, on: :create
  after_create :update_conversation_assignment
  after_update :update_conversation_on_resolve

  scope :active, -> {where(status: 'active')}
  scope :resolved, -> {where(status: 'resolved')}
  scope :by_expert, ->(expert) {where(expert: expert)}
  scope :recent, -> {order(assigned_at: :desc)}

  def resolve!
    update!(status: 'resolved', resolved_at: Time.current)
  end

  def active?
    status == 'active'
  end

  def resolved?
    status == 'resolved'
  end

  private

  def set_assigned_at
    self.assigned_at ||= Time.current
  end

  def update_conversation_assignment
    conversation.update!(assigned_expert: expert, status: 'active')
  end

  def update_conversation_on_resolve
    if saved_change_to_status? && status == 'resolved'
      conversation.update!(status: 'resolved')
    end
  end

  
end
