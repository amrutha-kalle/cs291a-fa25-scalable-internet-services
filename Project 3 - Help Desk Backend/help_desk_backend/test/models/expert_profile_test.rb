require "test_helper"

class ExpertProfileTest < ActiveSupport::TestCase

    test "expert profile should save w/o profile/links" do
        user = User.create!(username: "alice", password: "password")
        expert = ExpertProfile.new(user_id: user.id)
        assert expert.save, "valid expert did not save"
    end

    test "profile should be linked to existing user" do
        expert = ExpertProfile.new(user_id: 1234)
        assert not expert.save, "profile that's linked to non-existent user is mistakenly saved"
    end
end