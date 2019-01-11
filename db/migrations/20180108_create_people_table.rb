require 'sequel'

Sequel.migration do
  change do
    create_table(:people) do
      primary_key :id
      String :name, null: false
      String :email_address, null: false
      String :slack_username, null: true
    end
  end
end
