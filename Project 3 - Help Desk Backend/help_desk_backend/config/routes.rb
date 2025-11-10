Rails.application.routes.draw do

  # AUTH ROUTES
  post "/auth/register", to: "auth#register"
  post "/auth/login", to: "auth#login"
  post "/auth/logout", to: "auth#logout"
  post "/auth/refresh", to: "auth#refresh"
  get "/auth/me", to: "auth#me"
  
  # HEALTH ROUTE
  get "/health", to: "health#check"

  # EXPERT ROUTES
  get "/expert/profile", to: "expert#get_profile"
  put "/expert/profile", to: "expert#update_profile"
  get "/expert/queue", to: "expert#queue"
  post "/expert/conversations/:conversation_id/claim", to: "expert#claim"
  post "/expert/conversations/:conversation_id/unclaim", to: "expert#unclaim"
  get "/expert/assignments/history", to: "expert#history"


  # CONVERSATION ROUTES
  resources :conversations, only: [:index, :show, :create]

  # MESSAGE ROUTES
  resources :conversations, only: [] do
    resources :messages, only: [:index]
  end
  post "/messages", to: "messages#create"
  put "/messages/:id/read", to: "messages#mark_as_read"

  # UPDATE/POLLING ENDPOINTS ROUTES
  get "/api/conversations/updates", to: "updates#conversations"
  get "/api/messages/updates", to: "updates#messages"
  get "/api/expert-queue/updates", to: "updates#expert_queue"
  
end