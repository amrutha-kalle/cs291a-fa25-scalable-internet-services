require "test_helper"

class UserTest < ActiveSupport::TestCase

  # test that duplicate usernames are not saved
  test "unique username" do
    user1 = User.new(
      username: "alice",
      password: "password",
      password_confirmation: "password",
      last_active_at: Time.current
    )

    assert user1.save, "ERROR: user was not saved"

    user2 = User.create(
      username: "alice",
      password: "anotherpassword",
      password_confirmation: "anotherpassword",
      last_active_at: Time.current
    )

    assert_not user2.save, "ERROR: user with duplicate username was saved"
  end


  # make sure all user attributes are created correctly
  test "attributes exist" do
    user = User.new(
      username: "alice",
      password: "password",
      password_confirmation: "password",
      last_active_at: Time.current
    )

    assert user.save, "ERROR: user was not saved"

    assert_not_nil user.id,               "ERROR: id should not be null"
    assert_not_nil user.username,         "ERROR: username should not be null"
    assert_not_nil user.password_digest,  "ERROR: password should not be null"
    assert_not_nil user.last_active_at,   "ERROR: last_active_at should not be null"
    assert_not_nil user.created_at,       "ERROR: created_at should not be null"
    assert_not_nil user.updated_at,       "ERROR: updated_at should not be null"
  end

end
