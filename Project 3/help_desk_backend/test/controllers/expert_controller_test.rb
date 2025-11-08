require "test_helper"

class ExpertControllerTest < ActionDispatch::IntegrationTest

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
end
