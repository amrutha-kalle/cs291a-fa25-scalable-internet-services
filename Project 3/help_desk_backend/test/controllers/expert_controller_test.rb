require "test_helper"

class ExpertControllerTest < ActionDispatch::IntegrationTest

  def setup
    # Create regular user
    @user = User.create!(
      username: 'testuser',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    # Create expert user with profile
    @expert = User.create!(
      username: 'expertuser',
      password: 'password123', 
      password_confirmation: 'password123'
    )
    ExpertProfile.create!(
      user: @expert,
      bio: "Test expert",
      knowledge_base_links: []
    )

    @expert2 = User.create!(
      username: 'expert2user',
      password: 'password123', 
      password_confirmation: 'password123'
    )

    ExpertProfile.create!(
      user: @expert2,
      bio: "Test expert 2",
      knowledge_base_links: []
    )
  end

  test "expert profile automatically created during registration" do
    post "/auth/register", params: {username: "alice", password: "password"}
    assert_response :created
    
    user = User.find_by(username: "alice")
    assert user, "user should have been created"
    assert user.expert_profile, "expert profile should have been created automatically"

    expert_profile = user.expert_profile
    assert_equal "", expert_profile.bio
    assert_equal [], expert_profile.knowledge_base_links
    assert_not_nil expert_profile.created_at, "ERROR: created_at should not be null"
    assert_not_nil expert_profile.updated_at, "ERROR: updated_at should not be null"
  end

  test "user can get expert profile" do
    post "/auth/register", params: {username: "alice", password: "password"}
    assert_response :created
    token = JSON.parse(response.body)['token']

    get '/expert/profile', headers: {'Authorization' => 'Bearer #{token}'}
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal "", data["bio"]
    assert_equal [], data['knowledge_base_links']
  end

  test "should successfully update expert profile" do
    post "/auth/register", params: {username: "alice", password: "password"}
    assert_response :created
    token = JSON.parse(response.body)['token']
    uid = 

    put '/expert/profile', 
      headers: {'Authorization' => 'Bearer #{token}'}, 
      params: {bio: "new bio who diz", knowledge_base_links: ["google.com", "duckduckgo.com"]}
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "new bio who diz", response_data["bio"]
    assert_equal ["google.com", "duckduckgo.com"], response_data["knowledge_base_links"]
    
    user = User.find_by(username: "alice")
    ex_profile = user.expert_profile
    ex_profile.reload
    assert_equal "new bio who diz", ex_profile["bio"]
  end
  
  test "expert can view queue" do
    # Create some test conversations
    waiting_conv = Conversation.create!(title: 'Waiting', initiator: @user, status: 'waiting')
    assigned_conv = Conversation.create!(
      title: 'Assigned', 
      initiator: @user, 
      assigned_expert: @expert, 
      status: 'active'
    )
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']

    get '/expert/queue', headers: { 'Authorization' => "Bearer #{@expert_token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 1, response_data['waitingConversations'].length
    assert_equal 1, response_data['assignedConversations'].length
    assert_equal 'Waiting', response_data['waitingConversations'][0]['title']
    assert_equal 'Assigned', response_data['assignedConversations'][0]['title']
  end

  test "claim" do
    conversation = Conversation.create!(
      title: 'Test Conversation',
      initiator: @user,
      status: 'waiting'
    )
    
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']
    assert_difference('ExpertAssignment.count', 1) do
      post "/expert/conversations/#{conversation.id}/claim",
           headers: { 'Authorization' => "Bearer #{expert_token}" }
    end

    
    assert_response :success
    assert_equal true, JSON.parse(response.body)['success']
    
    conversation.reload
    assert_equal @expert, conversation.assigned_expert
    assert_equal 'active', conversation.status
  end

  test "cannot claim already assigned conversation" do
    conversation = Conversation.create!(
      title: 'Already Assigned',
      initiator: @user,
      assigned_expert: @expert2,
      status: 'active'
    )
    
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']
    post "/expert/conversations/#{conversation.id}/claim",
         headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :unprocessable_entity
    assert_equal 'Conversation is already assigned to an expert', JSON.parse(response.body)['error']
  end

  test "cannot claim non-existent conversation" do
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']
    post "/expert/conversations/99999/claim",
         headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :not_found
    assert_equal 'Conversation not found', JSON.parse(response.body)['error']
  end

  # UNCLAIM TESTS
  test "expert can unclaim assigned conversation" do
    conversation = Conversation.create!(
      title: 'Assigned Conversation',
      initiator: @user,
      assigned_expert: @expert,
      status: 'active'
    )
    
    assignment = ExpertAssignment.create!(
      conversation: conversation,
      expert: @expert,
      status: 'active',
      assigned_at: Time.current
    )
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']

    post "/expert/conversations/#{conversation.id}/unclaim",
         headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :success
    assert_equal true, JSON.parse(response.body)['success']
    
    conversation.reload
    assert_nil conversation.assigned_expert
    assert_equal 'waiting', conversation.status
    
    assignment.reload
    assert_equal 'unassigned', assignment.status
  end

  test "cannot unclaim conversation assigned to other expert" do
    conversation = Conversation.create!(
      title: 'Other Expert Conversation',
      initiator: @user,
      assigned_expert: @expert2,
      status: 'active'
    )
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']
    post "/expert/conversations/#{conversation.id}/unclaim",
         headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :forbidden
    assert_equal 'You are not assigned to this conversation', JSON.parse(response.body)['error']
  end

  test "cannot unclaim non-existent conversation" do
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']
    post "/expert/conversations/99999/unclaim",
         headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :not_found
    assert_equal 'Conversation not found', JSON.parse(response.body)['error']
  end

  # ASSIGNMENT HISTORY TESTS
  test "expert can view assignment history" do
    conversation = Conversation.create!(
      title: 'History Test Conversation',
      initiator: @user
    )
    
    assignment1 = ExpertAssignment.create!(
      conversation: conversation,
      expert: @expert,
      status: 'resolved',
      assigned_at: 2.days.ago,
      resolved_at: 1.day.ago
    )
    
    assignment2 = ExpertAssignment.create!(
      conversation: conversation,
      expert: @expert,
      status: 'active',
      assigned_at: Time.current
    )
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']
    get '/expert/assignments/history', headers: { 'Authorization' => "Bearer #{expert_token}" }
    
    assert_response :success
    response_data = JSON.parse(response.body)
    
    assert_equal 2, response_data.length
    assert_equal 'History Test Conversation', response_data[0]['conversationTitle']
    assert_equal 'resolved', response_data[1]['status']
    assert_equal 'active', response_data[0]['status']
  end

  test "assignment history returns empty when no assignments" do
    post '/auth/login', params: { username: 'expertuser', password: 'password123' }
    expert_token = JSON.parse(response.body)['token']
    get '/expert/assignments/history', headers: { 'Authorization' => "Bearer #{@xpert_token}" }
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal 0, response_data.length
  end

  # AUTHORIZATION TESTS
  test "non-expert cannot access expert endpoints" do
    post '/auth/login', params: { username: 'testuser', password: 'password123' }
    user_token = JSON.parse(response.body)['token']
    get '/expert/queue', headers: { 'Authorization' => "Bearer #{user_token}" }
    assert_response :not_found
    assert_equal 'Expert profile not found', JSON.parse(response.body)['error']
  end

  test "endpoints require authentication" do
    get '/expert/queue'
    assert_response :unauthorized
  end
end
