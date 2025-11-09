require "test_helper"

class ExpertControllerTest < ActionDispatch::IntegrationTest

  # test "expert profile automatically created during registration" do
  #   post "/auth/register", params: {username: "alice", password: "password"}
  #   assert_response :created
    
  #   user = User.find_by(username: "alice")
  #   assert user, "user should have been created"
  #   assert user.expert_profile, "expert profile should have been created automatically"

  #   expert_profile = user.expert_profile
  #   assert_equal "", expert_profile.bio
  #   assert_equal [], expert_profile.knowledge_base_links
  #   assert_not_nil expert_profile.created_at, "ERROR: created_at should not be null"
  #   assert_not_nil expert_profile.updated_at, "ERROR: updated_at should not be null"
  # end

  # test "user can get expert profile" do
  #   post "/auth/register", params: {username: "alice", password: "password"}
  #   assert_response :created
  #   token = JSON.parse(response.body)['token']

  #   get '/expert/profile', headers: {'Authorization' => 'Bearer #{token}'}
  #   assert_response :success

  #   data = JSON.parse(response.body)
  #   assert_equal "", data["bio"]
  #   assert_equal [], data['knowledge_base_links']
  # end

  # test "should successfully update expert profile" do
  #   post "/auth/register", params: {username: "alice", password: "password"}
  #   assert_response :created
  #   token = JSON.parse(response.body)['token']
  #   uid = 

  #   put '/expert/profile', 
  #     headers: {'Authorization' => 'Bearer #{token}'}, 
  #     params: {bio: "new bio who diz", knowledge_base_links: ["google.com", "duckduckgo.com"]}
    
  #   assert_response :success
  #   response_data = JSON.parse(response.body)
  #   assert_equal "new bio who diz", response_data["bio"]
  #   assert_equal ["google.com", "duckduckgo.com"], response_data["knowledge_base_links"]
    
  #   user = User.find_by(username: "alice")
  #   ex_profile = user.expert_profile
  #   ex_profile.reload
  #   assert_equal "new bio who diz", ex_profile["bio"]
  # end

  # def setup
  #   # Create regular user
  #   @user = User.create!(
  #     username: 'testuser',
  #     password: 'password123',
  #     password_confirmation: 'password123'
  #   )
    
  #   # Create expert user with profile
  #   @expert = User.create!(
  #     username: 'expertuser',
  #     password: 'password123', 
  #     password_confirmation: 'password123'
  #   )
    
  #   # Login as expert and get token
  #   # post '/auth/login', params: { username: 'expertuser', password: 'password123' }
  #   # @expert_token = JSON.parse(response.body)['token']
  #   # post '/auth/logout'

  #   # Login as regular user for some tests
  #   # post '/auth/login', params: { username: 'testuser', password: 'password123' }
  #   # @user_token = JSON.parse(response.body)['token']
  # end

  
  test "expert can view queue" do
    user = User.create!(
      username: 'testuser',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    # Create expert user with profile
    expert = User.create!(
      username: 'expertuser',
      password: 'password123', 
      password_confirmation: 'password123'
    )
    # Create some test conversations
    waiting_conv = Conversation.create!(title: 'Waiting', initiator: user, status: 'waiting')
    assigned_conv = Conversation.create!(
      title: 'Assigned', 
      initiator: user, 
      assigned_expert: expert, 
      status: 'active'
    )
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']

    get '/expert/queue', headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 1, response_data['waitingConversations'].length
    assert_equal 1, response_data['assignedConversations'].length
    assert_equal 'Waiting', response_data['waitingConversations'][0]['title']
    assert_equal 'Assigned', response_data['assignedConversations'][0]['title']
  end

  # test "expert can view assignment history" do
  #   conversation = Conversation.create!(title: 'Test', initiator: @user)
  #   assignment = ExpertAssignment.create!(
  #     conversation: conversation,
  #     expert: @expert,
  #     status: 'resolved',
  #     assigned_at: 1.day.ago,
  #     resolved_at: Time.current
  #   )

  #   get '/expert/assignments/history', headers: { 'Authorization' => "Bearer #{@expert_token}" }
    
  #   assert_response :success
  #   response_data = JSON.parse(response.body)
    
  #   assert_equal 1, response_data.length
  #   assert_equal 'Test', response_data[0]['conversationTitle']
  #   assert_equal 'resolved', response_data[0]['status']
  # end
end
