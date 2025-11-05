gem install rails
rails new help_desk_backend --api --skip-kamal --skip-thruster  --database=mysql
pwd
cd app/
ls
cd services/
ls
cd ../..
ls
cd help_desk_backend/
ls
gem "rack-cors"
bundle install
rails db:create
rails server -b 0.0.0.0 -p 3000
clear
rails generate active_record:session_migration
rails db:migrate
exit
