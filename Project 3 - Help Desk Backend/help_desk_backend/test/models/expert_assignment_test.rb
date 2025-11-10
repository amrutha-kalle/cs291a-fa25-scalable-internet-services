require "test_helper"

class ExpertAssignmentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      username: 'testuser',
      password: 'password123'
    )
    @expert = User.create!(
      username: 'expertuser', 
      password: 'password123'
    )
    @conversation = Conversation.create!(
      title: 'Test Conversation',
      initiator: @user
    )
  end

  test "should create valid expert assignment" do
    assignment = ExpertAssignment.new(
      conversation: @conversation,
      expert: @expert,
      status: 'active',
      assigned_at: Time.current
    )
    assert assignment.valid?
    assert assignment.save
  end

  test "should set default assigned_at on creation" do
    assignment = ExpertAssignment.create!(
      conversation: @conversation,
      expert: @expert,
      status: 'active'
    )
    assert_not_nil assignment.assigned_at
  end

  test "should set default status to active" do
    assignment = ExpertAssignment.new(
      conversation: @conversation,
      expert: @expert,
      assigned_at: Time.current
    )
    assignment.save
    assert_equal 'active', assignment.status
  end

  test "should not create assignment without conversation" do
    assignment = ExpertAssignment.new(
      expert: @expert,
      status: 'active',
      assigned_at: Time.current
    )
    assert_not assignment.valid?
    assert_includes assignment.errors[:conversation], "must exist"
  end

  test "should not create assignment without expert" do
    assignment = ExpertAssignment.new(
      conversation: @conversation,
      status: 'active',
      assigned_at: Time.current
    )
    assert_not assignment.valid?
    assert_includes assignment.errors[:expert], "must exist"
  end

  test "should validate status values" do
    assignment = ExpertAssignment.new(
      conversation: @conversation,
      expert: @expert,
      assigned_at: Time.current,
      status: 'invalid_status'
    )
    assert_not assignment.valid?
    assert_includes assignment.errors[:status], "is not included in the list"
  end
end
