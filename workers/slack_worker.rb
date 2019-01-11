require 'date'
require 'http'
require 'sidekiq'

class SlackWorker
  include Sidekiq::Worker

  def perform(pairs)
    number_of_pairs = (pairs.length / 2).ceil
    logger.debug "SlackWorker running for #{number_of_pairs} pairs"

    unless send_slack_messages?
      logger.info "Not sending Slack messages to #{number_of_pairs} pairs because `SEND_SLACK_MESSAGES` environment variable is not set to `true`."
      return
    end

    unless env_vars_set?
      logger.info 'Not sending Slack messages because one or more environment variables are not set.'
      return
    end

    pairs.each do |pair|
      if pair.length == 1
        logger.debug "Sending a no-pairing Slack message to @#{pair[0]['slack_username']}"
        send_slack_message(pair[0]['slack_username'], slack_message_body_no_pairing)
      else
        logger.debug "Sending a pairing Slack message to @#{pair[0]['slack_username']} and @#{pair[1]['slack_username']}"
        send_slack_message(pair[0]['slack_username'], slack_message_body(pair[1]['name']))
        send_slack_message(pair[1]['slack_username'], slack_message_body(pair[0]['name']))
      end
    end
  end

  private

  def send_slack_messages?
    ENV['SEND_SLACK_MESSAGES'] == 'true'
  end

  def env_vars_set?
    ENV['SEND_SLACK_MESSAGES'] && ENV['SLACK_WEBHOOK_URL']
  end

  def this_month
    @this_month ||= Date.today.strftime('%B %Y')
  end

  def slack_incoming_webhook_url
    @slack_incoming_webhook_url ||= ENV['SLACK_WEBHOOK_URL']
  end

  def slack_message_body(their_name)
    <<~BODY
      Hello :wave:
      Your random coffee partner for #{this_month} is #{their_name}. Please set up a time to meet them for a coffee!
    BODY
  end

  def slack_message_body_no_pairing
    <<~BODY
      Hello :wave:
      Unfortunately, we weren't able to find someone to pair you with for random coffee this month. Better luck next month!
    BODY
  end

  def send_slack_message(recipient, body)
    payload = {
      username: 'Mocha Bot',
      icon_emoji: ':coffee:',
      text: body,
      mrkdwn: true,
      channel: "@#{recipient}"
    }

    HTTP.post(slack_incoming_webhook_url, body: JSON.dump(payload))
  end
end
