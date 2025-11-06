class User < ApplicationRecord

    has_secure_password

    # validations
    validates :username, presence: true, uniqueness: true
    validates :password_digest, presence: true

    # associations
    has_one :expert_profile, dependent: :destroy
end

