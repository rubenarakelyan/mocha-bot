require_relative '../../workers/slack_worker'

RSpec.describe SlackWorker, '#perform' do
  let(:pairs) do
    [
      [
        {
          'name' => 'Person 1',
          'email_address' => 'person-1@example.com'
        },
        {
          'name' => 'Person 2',
          'email_address' => 'person-2@example.com',
          'slack_username' => 'person.two'
        }
      ],
      [
        {
          'name' => 'Person 3',
          'email_address' => 'person-3@example.com',
          'slack_username' => 'person-three'
        }
      ]
    ]
  end

  before do
    ENV['SEND_SLACK_MESSAGES'] = 'true'
    ENV['SLACK_WEBHOOK_URL'] = 'https://fake.slack.endpoint.example.com/some/other/stuff'
    stub_request(:post, ENV['SLACK_WEBHOOK_URL']).to_return(status: 200)
  end

  context 'when called' do
    it 'sends an appropriate Slack message to each person' do
      SlackWorker.new.perform(pairs)
      expect(WebMock).to have_requested(:post, ENV['SLACK_WEBHOOK_URL'])
        .with(body: /Your random coffee partner for .+ is .+/).twice
      expect(WebMock).to have_requested(:post, ENV['SLACK_WEBHOOK_URL'])
        .with(body: /Unfortunately, we weren't able to find someone to pair you with for random coffee this month/).once
    end
  end
end
