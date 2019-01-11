require 'aws-sdk-ses'
require 'date'
require 'sidekiq'

class EmailWorker
  include Sidekiq::Worker

  def perform(pairs)
    number_of_pairs = (pairs.length / 2).ceil
    logger.debug "EmailWorker running for #{number_of_pairs} pairs"

    unless send_emails?
      logger.info "Not sending emails to #{number_of_pairs} pairs because `SEND_EMAILS` environment variable is not set to `true`."
      return
    end

    unless env_vars_set?
      logger.info 'Not sending emails because one or more environment variables are not set.'
      return
    end

    @ses = Aws::SES::Client.new(region: aws_ses_region)

    pairs.each do |pair|
      if pair.length == 1
        logger.debug "Sending a no-pairing email to #{pair[0]['email_address']}"
        send_email(pair[0]['email_address'], email_body_no_pairing(pair[0]['name']))
      else
        logger.debug "Sending a pairing email to #{pair[0]['email_address']} and #{pair[1]['email_address']}"
        send_email(pair[0]['email_address'], email_body(pair[0]['name'], pair[1]['name']))
        send_email(pair[1]['email_address'], email_body(pair[1]['name'], pair[0]['name']))
      end
    end
  rescue Aws::SES::Errors::ServiceError => error
    logger.debug "Got an error from AWS SES when attempting to send an email: #{error}"
  end

  private

  def send_emails?
    ENV['SEND_EMAILS'] == 'true'
  end

  def env_vars_set?
    ENV['SEND_EMAILS'] && ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY'] &&
      ENV['AWS_REGION'] && ENV['EMAIL_FROM']
  end

  def this_month
    @this_month ||= Date.today.strftime('%B %Y')
  end

  def aws_ses_region
    @aws_ses_region ||= ENV['AWS_REGION']
  end

  def aws_ses_sender
    @aws_ses_sender ||= "Mocha Bot <#{ENV['EMAIL_FROM']}>"
  end

  def aws_ses_subject
    @aws_ses_subject ||= "Your random coffee pairing for #{this_month}"
  end

  def email_body(your_name, their_name)
    <<~BODY
      Hi #{your_name},

      Your random coffee partner for #{this_month} is #{their_name}. Please set up a time to meet them for a coffee!

      Thanks,

      Mocha Bot
    BODY
  end

  def email_body_no_pairing(your_name)
    <<~BODY
      Hi #{your_name},

      Unfortunately, we weren't able to find someone to pair you with for random coffee this month. Better luck next month!

      Thanks,

      Mocha Bot
    BODY
  end

  def send_email(recipient, body)
    @ses.send_email(
      destination: {
        to_addresses: [
          recipient
        ]
      },
      message: {
        body: {
          text: {
            charset: 'UTF-8',
            data: body
          }
        },
        subject: {
          charset: 'UTF-8',
          data: aws_ses_subject
        }
      },
      source: aws_ses_sender
    )
  end
end
