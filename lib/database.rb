require 'sequel'

class Database
  def self.connect
    @connect ||= Sequel.connect(database_url)
  end

  def self.database_url
    ENV['DATABASE_URL'] || 'sqlite://db/development.sqlite'
  end
  private_class_method :database_url
end
