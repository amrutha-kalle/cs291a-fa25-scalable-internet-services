require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      username: 'testuser',
      password: 'password123'
    )
  end

  test 'should be valid' do
    assert @user.valid?
  end

  test 'unique username' do
    @user.save
    duplicate_user = User.new(
      username: 'testuser',
      passowrd: 'anotherpassword'
    )
    assert_not_duplicate.valid?
  end

end
