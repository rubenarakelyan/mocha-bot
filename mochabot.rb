require 'sinatra'
require_relative 'lib/database'
require_relative 'lib/notifications'
require_relative 'lib/random_pairer'

helpers do
  def admin_protected!
    return if admin_authorized?

    headers['WWW-Authenticate'] = 'Basic realm="Admin Area"'
    halt 401, erb(:error_not_authorised, locals: { error_message: 'Only administrators can carry out the random coffee draw.' })
  end

  def user_protected!
    return if user_authorized?

    headers['WWW-Authenticate'] = 'Basic realm="User Area"'
    halt 401, erb(:error_not_authorised, locals: { error_message: 'Please log in to add yourself.' })
  end

  def admin_authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', ENV['ADMIN_PASSWORD']]
  end

  def user_authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['user', ENV['USER_PASSWORD']]
  end
end

raise 'The ADMIN_PASSWORD and USER_PASSWORD environment variables must be set to run this application.' unless ENV['ADMIN_PASSWORD'] && ENV['USER_PASSWORD']

get '/' do
  erb :index
end

get '/user/add' do
  user_protected!
  erb :user_add, locals: { form_valid: true, name: nil, email_address: nil, slack_username: nil }
end

post '/user/add' do
  user_protected!
  if params['name'].empty? || params['email_address'].empty?
    erb :user_add, locals: { form_valid: false, name: params['name'], email_address: params['email_address'], slack_username: params['slack_username'] }
  else
    add_person(params['name'], params['email_address'], params['slack_username'])
    erb :user_added, locals: { name: params['name'] }
  end
end

get '/admin' do
  admin_protected!
  erb :admin, locals: { people: people, form_valid: true, email_address: nil }
end

post '/draw' do
  admin_protected!
  admin_email_address = params['email_address']
  if admin_email_address.empty?
    erb :admin, locals: { people: people, form_valid: false, email_address: admin_email_address }
  else
    pairs = RandomPairer.pair(people)
    Notifications.send(pairs, admin_email_address)
    erb :draw, locals: { admin_email_address: admin_email_address, send_emails: send_emails?, send_slack_messages: send_slack_messages? }
  end
end

post '/user/delete-confirm' do
  admin_protected!
  erb :user_delete_confirm, locals: { person: person_by_id(params['person_id']) }
end

post '/user/delete' do
  admin_protected!
  name = person_by_id(params['person_id'])[:name]
  delete_person(params['person_id'])
  erb :user_deleted, locals: { name: name }
end

private

def send_emails?
  ENV['SEND_EMAILS'] == 'true'
end

def send_slack_messages?
  ENV['SEND_SLACK_MESSAGES'] == 'true'
end

def people
  db = Database.connect
  db[:people].order(:name).all
end

def person_by_id(id)
  db = Database.connect
  db[:people].where(id: id).first
end

def add_person(name, email_address, slack_username)
  db = Database.connect
  db[:people].insert(name: name, email_address: email_address, slack_username: slack_username)
end

def delete_person(id)
  db = Database.connect
  db[:people].where(id: id).delete
end
