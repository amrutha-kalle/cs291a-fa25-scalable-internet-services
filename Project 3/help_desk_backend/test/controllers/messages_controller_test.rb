require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: 'alice', password: 'password')
    @expert = User.create!(username: 'bob', password: 'password')
    @conversation = Conversation.create!(title: 'Test', initiator: @user, assigned_expert: @expert, status: 'active')
    post '/auth/login', params: { username: 'alice', password: 'password' }
    @user_token = JSON.parse(response.body)['token']
  end

  test "should create message" do
    assert_difference('Message.count', 1) do
      post '/messages',
           headers: { 'Authorization' => "Bearer #{@user_token}" },
           params: { 
             content: 'Hello expert',
             conversationId: @conversation.id
           }
    end
    assert_response :created
    response_body = JSON.parse(response.body)
    assert_equal "alice", response_body['senderUsername']
    assert_equal "Hello expert", response_body['content']
    assert_equal false, response_body['isRead']
  end

  test "should get message" do
    post '/messages',
      headers: { 'Authorization' => "Bearer #{@user_token}" },
      params: { 
        content: 'Hello expert',
        conversationId: @conversation.id
      }
    assert_response :created
    get "/conversations/#{@conversation.id}/messages", headers: { 'Authorization' => "Bearer #{@user_token}" }
    
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
  end

  test "expert should get message" do
    post '/messages',
      headers: { 'Authorization' => "Bearer #{@user_token}" },
      params: { 
        content: 'Hello expert',
        conversationId: @conversation.id
      }
    assert_response :created

    post '/auth/logout'
    assert_response :ok

    post '/auth/login', params: { username: 'bob', password: 'password' }
    assert_response :ok
    expert_token = JSON.parse(response.body)['token']
    expert_headers = { 'Authorization' => "Bearer #{expert_token}" }

    get "/conversations/#{@conversation.id}/messages", headers: expert_headers
    
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal "Hello expert", body.first["content"]
    assert_equal "alice", body.first["senderUsername"]
    assert_equal "initiator", body.first["senderRole"]
  end

  test "user should see message expert sent" do
    post '/messages',
      headers: { 'Authorization' => "Bearer #{@user_token}" },
      params: { 
        content: 'Hello expert',
        conversationId: @conversation.id
      }
    assert_response :created

    post '/auth/logout'
    assert_response :ok

    post '/auth/login', params: { username: 'bob', password: 'password' }
    assert_response :ok
    expert_token = JSON.parse(response.body)['token']
    post '/messages',
      headers: { 'Authorization' => "Bearer #{expert_token}" },
      params: { 
        content: 'Hello initiator',
        conversationId: @conversation.id
      }
    assert_response :created

    post '/auth/logout'
    assert_response :ok

    post '/auth/login', params: { username: 'alice', password: 'password' }
    assert_response :ok
    user_token = JSON.parse(response.body)['token']

    get "/conversations/#{@conversation.id}/messages", headers: { 'Authorization' => "Bearer #{user_token}" }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 2, body.length
    assert_equal "Hello expert", body.first["content"]
    assert_equal "alice", body.first["senderUsername"]
    assert_equal "initiator", body.first["senderRole"]
    assert_equal "Hello initiator", body.second["content"]
    assert_equal "bob", body.second["senderUsername"]
    assert_equal "expert", body.second["senderRole"]
    
  end

  test "should mark message as read" do
    post '/messages',
      headers: { 'Authorization' => "Bearer #{@user_token}" },
      params: { 
        content: 'Hello expert',
        conversationId: @conversation.id
      }
    assert_response :created
    message = JSON.parse(response.body)

    post '/auth/logout'
    assert_response :ok

    post '/auth/login', params: {username: 'bob', password: 'password'}
    expert_token = JSON.parse(response.body)['token']

    put "/messages/#{message["id"]}/read", headers: { 'Authorization' => "Bearer #{expert_token}" }
    assert_response :ok
    assert_equal true, JSON.parse(response.body)["success"]
  end

  test "should not mark own message as read" do
    post '/messages',
      headers: { 'Authorization' => "Bearer #{@user_token}" },
      params: { 
        content: 'Hello expert',
        conversationId: @conversation.id
      }
    assert_response :created
    message = JSON.parse(response.body)

    put "/messages/#{message["id"]}/read", headers: { 'Authorization' => "Bearer #{@user_token}" }
    assert_response :forbidden
  end

  test "get messages returns empty array when no messages" do
    get "/conversations/#{@conversation.id}/messages", headers:{ 'Authorization' => "Bearer #{@user_token}" }
    
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body
  end
end
