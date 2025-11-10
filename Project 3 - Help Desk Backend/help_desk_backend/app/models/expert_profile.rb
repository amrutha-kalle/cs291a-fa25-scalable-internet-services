class ExpertProfile < ApplicationRecord
    belongs_to :user

    # validations
    validates :user_id, presence: true, uniqueness: true
    
end
