require_relative '../../lib/notifications'

RSpec.describe Notifications, '#send' do
  let(:pairs) do
    [
      [
        {
          name: 'Person 1',
          email_address: 'person-1@example.com'
        },
        {
          name: 'Person 2',
          email_address: 'person-2@example.com',
          slack_username: 'person.two'
        }
      ],
      [
        {
          name: 'Person 3',
          email_address: 'person-3@example.com',
          slack_username: 'person-three'
        }
      ]
    ]
  end
  let(:admin_email_address) { 'admin@example.com' }

  context 'when called' do
    it 'enqueues a CsvWorker Sidekiq job' do
      Notifications.send(pairs, admin_email_address)
      expect(CsvWorker).to have_enqueued_sidekiq_job(pairs, admin_email_address)
    end

    it 'enqueues an EmailWorker Sidekiq job' do
      Notifications.send(pairs, admin_email_address)
      expect(EmailWorker).to have_enqueued_sidekiq_job(pairs)
    end

    it 'enqueues a SlackWorker Sidekiq job' do
      Notifications.send(pairs, admin_email_address)
      expect(SlackWorker).to have_enqueued_sidekiq_job(pairs)
    end
  end
end
