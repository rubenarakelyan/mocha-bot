release: bundle exec sequel -m db/migrations $DATABASE_URL
web: bundle exec puma -C ./config/puma.rb
worker: bundle exec sidekiq -r ./lib/notifications.rb -t 25
