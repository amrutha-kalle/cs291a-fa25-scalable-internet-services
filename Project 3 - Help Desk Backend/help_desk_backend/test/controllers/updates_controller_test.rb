require "test_helper"

class UpdatesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      username: 'testuser',
      password: 'password',
      password_confirmation: 'password'
    )
    
    @expert = User.create!(
      username: 'expertuser',
      password: 'password',
      password_confirmation: 'password'
    )

    ExpertProfile.create!(user: @expert, bio: 'Test expert', knowledge_base_links: [])
    
    @user_conversation = Conversation.create!(
      title: 'User Conversation',
      initiator: @user,
      status: 'waiting'
    )
    
    @expert_conversation = Conversation.create!(
      title: 'Expert Conversation',
      initiator: @user,
      assigned_expert: @expert,
      status: 'active'
    )
    
    @message = Message.create!(
      conversation: @user_conversation,
      sender: @user,
      sender_role: 'initiator',
      content: 'Hello expert',
      is_read: false
    )
  end

  test "GET /api/conversations/updates returns conversations for user as initiator" do
    post "/auth/login", params: {username: 'testuser', password: "password"}
    assert_response :ok
    user_token = JSON.parse(response.body)['token']

    get '/api/conversations/updates', params: { userId: @user.id }, headers: { 'Authorization' => "Bearer #{user_token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 2, response_data.length
    
    conversation_titles = response_data.map { |c| c['title'] }
    assert_includes conversation_titles, 'User Conversation'
    assert_includes conversation_titles, 'Expert Conversation'
  end

  test "GET /api/conversations/updates returns conversations for expert as assigned expert" do
    post "/auth/login", params: {username: 'expertuser', password: "password"}
    assert_response :ok
    expert_token = JSON.parse(response.body)['token']
    get '/api/conversations/updates', params: { userId: @expert.id }, headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)

    assert_equal 1, response_data.length
    assert_equal 'Expert Conversation', response_data[0]['title']
    assert_equal 'active', response_data[0]['status']
  end

  test "GET /api/messages/updates returns messages for user conversations" do
    Message.create!(
      conversation: @expert_conversation,
      sender: @expert,
      sender_role: 'expert',
      content: 'Hello user',
      is_read: false
    )

    post "/auth/login", params: {username: 'testuser', password: "password"}
    assert_response :ok
    user_token = JSON.parse(response.body)['token']
    get '/api/messages/updates', params: { userId: @user.id }, headers: { 'Authorization' => "Bearer #{user_token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    

    assert_equal 2, response_data.length
    
    message_contents = response_data.map { |m| m['content'] }
    assert_includes message_contents, 'Hello expert'
    assert_includes message_contents, 'Hello user'
  end

  test "GET /api/expert-queue/updates returns expert queue" do
    post "/auth/login", params: {username: 'expertuser', password: "password"}
    assert_response :ok
    expert_token = JSON.parse(response.body)['token']
    get '/api/expert-queue/updates', params: { expertId: @expert.id }, headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 1, response_data.length
    assert response_data[0]['waitingConversations'].is_a?(Array)
    assert response_data[0]['assignedConversations'].is_a?(Array)
    
    # Expert should see their assigned conversation in assignedConversations
    assigned_conv_titles = response_data[0]['assignedConversations'].map { |c| c['title'] }
    assert_includes assigned_conv_titles, 'Expert Conversation'
  end

end
