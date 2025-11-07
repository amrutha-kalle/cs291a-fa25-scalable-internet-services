class User < ApplicationRecord

    has_secure_password

    # validations
    validates :username, presence: true, uniqueness: true
    validates :password_digest, presence: true

    # set last_active_at automatically
    before_create :set_initial_last_active

    # associations
    has_one :expert_profile, dependent: :destroy

    private

    def set_initial_last_active
        self.last_active_at ||= Time.current
    end
    
end

