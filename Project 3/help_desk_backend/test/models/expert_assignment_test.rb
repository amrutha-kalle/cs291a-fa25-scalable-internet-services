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

  # Basic Creation Tests
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
    # assert_in_delta Time.current, assignment.assigned_at, 1.second
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

  # Validation Tests
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

  # Status Method Tests
  # test "active? should return true for active assignments" do
  #   assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )
  #   assert assignment.active?
  # end

  # test "resolved? should return true for resolved assignments" do
  #   assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'resolved'
  #   )
  #   assert assignment.resolved?
  # end

  # # Scope Tests
  # test "active scope should return only active assignments" do
  #   active_assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )
  #   resolved_assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'resolved'
  #   )

  #   active_assignments = ExpertAssignment.active
  #   assert_includes active_assignments, active_assignment
  #   assert_not_includes active_assignments, resolved_assignment
  # end

  # test "resolved scope should return only resolved assignments" do
  #   active_assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )
  #   resolved_assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'resolved'
  #   )

  #   resolved_assignments = ExpertAssignment.resolved
  #   assert_includes resolved_assignments, resolved_assignment
  #   assert_not_includes resolved_assignments, active_assignment
  # end

  # test "by_expert scope should return assignments for specific expert" do
  #   another_expert = User.create!(
  #     username: 'anotherexpert',
  #     password: 'password123',
  #     password_confirmation: 'password123'
  #   )

  #   assignment1 = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )
  #   assignment2 = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: another_expert,
  #     status: 'active'
  #   )

  #   expert_assignments = ExpertAssignment.by_expert(@expert)
  #   assert_includes expert_assignments, assignment1
  #   assert_not_includes expert_assignments, assignment2
  # end

  # # Instance Method Tests
  # test "resolve! should update status and resolved_at" do
  #   assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )

  #   assignment.resolve!
  #   assignment.reload

  #   assert_equal 'resolved', assignment.status
  #   assert_not_nil assignment.resolved_at
  #   assert_in_delta Time.current, assignment.resolved_at, 1.second
  # end

  # # Callback Tests
  # test "should update conversation assignment on create" do
  #   assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )

  #   @conversation.reload
  #   assert_equal @expert, @conversation.assigned_expert
  #   assert_equal 'active', @conversation.status
  # end

  # test "should update conversation status when resolved" do
  #   assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )

  #   assignment.resolve!
  #   @conversation.reload
  #   assert_equal 'resolved', @conversation.status
  # end

  # # Edge Cases
  # test "should handle multiple assignments for same conversation" do
  #   assignment1 = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )

  #   # Create another assignment (simulating expert reassignment)
  #   assignment2 = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'active'
  #   )

  #   assert ExpertAssignment.where(conversation: @conversation).count >= 2
  # end

  # test "should not update resolved_at when status changes to active" do
  #   assignment = ExpertAssignment.create!(
  #     conversation: @conversation,
  #     expert: @expert,
  #     status: 'resolved',
  #     resolved_at: 1.day.ago
  #   )

  #   original_resolved_at = assignment.resolved_at
  #   assignment.update!(status: 'active')
    
  #   assert_equal original_resolved_at, assignment.resolved_at
  # end
end
