Rails.application.routes.draw do

  # AUTH ROUTES
  post '/auth/register', to: 'auth#register'
  post '/auth/login', to: 'auth#login'
  post '/auth/logout', to: 'auth#logout'
  post '/auth/refresh', to: 'auth#refresh'
  get '/auth/me', to: 'auth#me'
  
  # HEALTH ROUTE
  get '/health', to: 'health#check'

  # EXPERT ROUTES
  get '/expert/profile', to: 'expert#get_profile'
  put '/expert/profile', to: 'expert#update_profile'


  # CONVERSATION ROUTES
  resources :conversations, only: [:index, :show, :create]
end