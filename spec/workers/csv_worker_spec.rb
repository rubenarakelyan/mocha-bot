require_relative '../../workers/csv_worker'

RSpec.describe CsvWorker, '#build_csv' do
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

  context 'when called' do
    it 'builds a valid CSV string with a header and two lines of output' do
      csv = CsvWorker.new.send(:build_csv, pairs)
      expect(csv).to start_with('First person,Second person')
      expect(csv.split("\n").length).to eq(3)
    end
  end
end

RSpec.describe CsvWorker, '#build_email' do
  let(:admin_email_address) { 'admin@example.com' }
  let(:csv) { "First person,Second person\nPerson 2,Person 3\nPerson 1" }

  context 'when called' do
    it 'builds a valid multipart/mixed email with a text body and CSV attachment' do
      email = CsvWorker.new.send(:build_email, admin_email_address, csv)
      expect(
        email.body.body.instance_variable_get(:@body)[0].body.instance_variable_get(:@body)[0].body
      ).to include('The results of the random coffee draw')
      expect(
        email.body.body.instance_variable_get(:@body)[1].instance_variable_get(:@disposition)
      ).to eq('attachment; filename=random_coffee_pairings.csv')
    end
  end
end
