# Mocha Bot

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Mocha Bot is an app that takes a list of people, and randomly draws pairs to participate in a round of random coffee.

People can sign themselves up to participate by entering their name, email address and (optionally) a Slack username. There is no authentication of individuals, so it runs on an honesty basis. However, there is overall HTTP authentication to prevent random people on the Internet from signing up people. Additionally, all admin functions are protected by separate HTTP authentication.

The pairs are output as a CSV file that can be imported into any spreadsheet app. Optionally, the app can also email and direct message the revelant people using Slack to let them know of their random coffee partner.

## Technical implementation

Mocha Bot is a Ruby app using the [Sinatra](http://sinatrarb.com) framework and [Sidekiq](https://sidekiq.org/) for asynchronous jobs.

### Prerequisites

* Ruby 2.5.1
* rbenv or another way of managing Ruby versions
* Redis
* An AWS account with IAM and SES configured to send emails
* A Slack account with credentials to post messages (if Slack messaging is enabled)

### Environment variables

* `DATABASE_URL`: Set to the URL to use to connect to your database (automatically set by Heroku)
* `ADMIN_PASSWORD`: Set to a password used to trigger the random coffee draw
* `USER_PASSWORD`: Set to a password used by users to add themselves
* `SEND_EMAILS`: Set to `true` to enable email sending (note that CSV emails are always sent)
* `SEND_SLACK_MESSAGES`: Set to `true` to enable Slack messaging
* `AWS_ACCESS_KEY_ID`: Set to your AWS access key ID
* `AWS_SECRET_ACCESS_KEY`: Set to your AWS secret access key
* `AWS_REGION`: Set to the relevant AWS region
* `EMAIL_FROM`: Set to the email address you want to send emails from (must be added and verified in AWS)

If Slack messaging is enabled:

* `SLACK_WEBHOOK_URL`: Set to your Slack webhook URL

### AWS configuration

* Create a user in IAM and give it permission to send emails using SES
* Generate an access key ID and secret access key for the user
* (If not already done) add the domain you'll be sending from and verify it
* Add the email address you'll be sending from and verify it

### Slack configuration

* Install the "Incoming WebHooks" app in your Slack workspace
* Create a new configuration and get the webhook URL

## Running the application

```
$ bundle exec puma -C ./config/puma.rb
```
for the app.

```
$ bundle exec sidekiq -r ./lib/notifications.rb
```
for the Sidekiq workers.

## Running the app tests

```
$ bundle exec rake
```
for running the RSpec and linting tests.

## Installing dependencies in development

```
$ bundle install --without production
```

## Running database migrations

```
$ bundle exec sequel -m db/migrations $DATABASE_URL
```

## Licence

[MIT licence](LICENCE)
