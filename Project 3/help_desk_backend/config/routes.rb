Rails.application.routes.draw do
  # Simple auth routes (no namespace)
  post '/auth/register', to: 'auth#register'
  post '/auth/login', to: 'auth#login'
  post '/auth/logout', to: 'auth#logout'
  post '/auth/refresh', to: 'auth#refresh'
  get '/auth/me', to: 'auth#me'
  
  get '/health', to: 'health#check'
end