source 'https://rubygems.org'

ruby File.read('.ruby-version').strip

gem 'aws-sdk-ses'
gem 'http'
gem 'mime'
gem 'puma'
gem 'rack'
gem 'rake'
gem 'sequel'
gem 'sidekiq'
gem 'sinatra'

group :production do
  gem 'pg'
end

group :test, :development do
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rspec-sidekiq'
  gem 'rubocop', require: false
  gem 'sqlite3'
  gem 'webmock'
end
