require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  def setup
    @current_user = User.create(username: "alice", password: "password")
  end

  test "conversation must have title" do
    conversation = Conversation.new(initiator: @current_user)
    assert_not conversation.save, "conversation without title was saved"
  end

  test "valid convo" do
    conversation = Conversation.new(initiator: @current_user, title: "test convo")
    assert conversation.save, "valid convo was not saved"
  end

  test "all features of convo should exist" do
    conversation = Conversation.create(initiator: @current_user, title: "test")
    assert conversation.persisted?, "convo was not saved"
    assert_not_nil conversation.id, "ERROR: id should not be null"
    assert_not_nil conversation.title, "title should not be null"
    assert_not_nil conversation.status, "status should not be null"
    assert_not_nil conversation.initiator, "initiator should not be null"
  end
end
