require "test_helper"

class MessageTest < ActiveSupport::TestCase
  
  def setup
    @user = User.create!(username: "alice", password: "password")
    @conversation = Conversation.create!(title: "test convo", initiator: @user)
  end


  test "message should be tied to convo" do
    message = Message.new(sender: @user, sender_role: 'initiator', content: "test message")
    assert_not message.save, "invalid message should not be saved"
  end

  test "message must have content, sender, (valid) sender_role" do
    message1 = Message.new(conversation: @conversation, sender: @user, content: "test")
    assert_not message1.save, "msg should not save without sender role"
    message2 = Message.new(conversation: @conversation, sender: @user, sender_role: "initiator")
    assert_not message2.save, "msg should not save without content"
    message3 = Message.new(conversation: @conversation, sender: @user, sender_role: "middleman", content: "test")
    assert_not message3.save, "msg should not save without valid sender role"
    message4 = Message.new(conversation: @conversation, sender: @user, sender_role: "expert", content: "test")
    assert message4.save, "msg should have been saved with expert role"
  end

  test "all attributes" do
    message = Message.create!(conversation: @conversation, sender: @user, sender_role: "initiator", content: "test")
    assert message.persisted?, "message was not saved"

    assert_not_nil message.id, "ERROR: id should not be null"
    assert_not_nil message.conversation_id, "ERROR: conversation_id should not be null"
    assert_not_nil message.sender_id, "ERROR: sender_id should not be null"
    assert_not_nil message.sender_role, "ERROR: sender_role should not be null"
    assert_not_nil message.content, "ERROR: content should not be null"
    assert_not_nil message.is_read, "ERROR: is_read should not be null"
    assert_not_nil message.created_at, "ERROR: created_at should not be null"
    assert_not_nil message.updated_at, "ERROR: updated_at should not be null"

    assert_equal "test", message.content
    assert_equal "initiator", message.sender_role
    assert_equal false, message.is_read
  end
end
