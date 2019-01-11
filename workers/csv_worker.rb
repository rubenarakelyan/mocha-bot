require 'aws-sdk-ses'
require 'base64'
require 'csv'
require 'mime'
require 'sidekiq'

class CsvWorker
  include Sidekiq::Worker

  def perform(pairs, admin_email_address)
    number_of_pairs = (pairs.length / 2).ceil
    logger.debug "CsvWorker running for #{number_of_pairs} pairs"

    unless env_vars_set?
      logger.info 'Not sending CSV email because one or more environment variables are not set.'
      return
    end

    csv = build_csv(pairs)
    send_email_with_csv(admin_email_address, csv)
  end

  private

  def env_vars_set?
    ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY'] && ENV['AWS_REGION'] && ENV['EMAIL_FROM']
  end

  def this_month
    @this_month ||= Date.today.strftime('%B %Y')
  end

  def aws_ses_region
    @aws_ses_region ||= ENV['AWS_REGION']
  end

  def aws_ses_sender
    @aws_ses_sender ||= ENV['EMAIL_FROM']
  end

  def aws_ses_subject
    @aws_ses_subject ||= "Random coffee pairings for #{this_month}"
  end

  def email_body
    <<~BODY
      Hi,

      The results of the random coffee draw for #{this_month} are attached to this email.

      The attachment is a CSV file that can be opened by any text editor or spreadsheet software.

      Thanks,

      Mocha Bot
    BODY
  end

  def build_csv(pairs)
    CSV.generate do |csv|
      csv << ['First person', 'Second person']
      pairs.each do |pair|
        first_person = pair[0]['name']
        second_person = pair[1].nil? ? nil : pair[1]['name']
        csv << [first_person, second_person]
      end
    end
  end

  def send_email_with_csv(recipient, csv)
    msg = build_email(recipient, csv)
    logger.debug "Sending an email with CSV attachment to #{recipient}"
    ses = Aws::SES::Client.new(region: aws_ses_region)
    ses.send_raw_email(
      raw_message: {
        data: msg.to_s
      }
    )
  rescue Aws::SES::Errors::ServiceError => error
    logger.debug "Got an error from AWS SES when attempting to send an email: #{error}"
  end

  def build_email(recipient, csv)
    # Build the email body
    msg_body = MIME::Multipart::Alternative.new
    msg_body.add(MIME::Text.new(email_body, 'plain'))

    # Build the attachment
    attachment = MIME::Application.new(Base64.encode64(csv))
    attachment.transfer_encoding = 'base64'
    attachment.disposition = 'attachment'

    # Put the email body and attachment together
    msg_mixed = MIME::Multipart::Mixed.new
    msg_mixed.add(msg_body)
    msg_mixed.attach(attachment, 'filename' => 'random_coffee_pairings.csv')

    # Make a new email with the multipart/mixed contents
    msg = MIME::Mail.new(msg_mixed)
    msg.to = { recipient => nil }
    msg.from = { aws_ses_sender.dup => 'Mocha Bot' }
    msg.subject = aws_ses_subject

    msg
  end
end
