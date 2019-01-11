require_relative '../workers/csv_worker'
require_relative '../workers/email_worker'
require_relative '../workers/slack_worker'

class Notifications
  def self.send(pairs, admin_email_address)
    CsvWorker.perform_async(pairs, admin_email_address)
    EmailWorker.perform_async(pairs)
    SlackWorker.perform_async(pairs)
  end
end
