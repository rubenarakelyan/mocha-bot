require_relative '../../lib/random_pairer'

RSpec.describe RandomPairer, '#pair' do
  let(:person) do
    {
      name: 'Person 1',
      email_address: 'person-1@example.com'
    }
  end
  let(:people) do
    [
      {
        name: 'Person 1',
        email_address: 'person-1@example.com'
      },
      {
        name: 'Person 2',
        email_address: 'person-2@example.com',
        slack_username: 'person.two'
      },
      {
        name: 'Person 3',
        email_address: 'person-3@example.com',
        slack_username: 'person-three'
      }
    ]
  end

  context 'when there are no people in the database' do
    it 'raises an exception' do
      expect { RandomPairer.pair([]) }.to raise_error(StandardError, 'There are no people in the database')
    end
  end

  context 'when there is one person in the database' do
    it 'raises an exception' do
      expect { RandomPairer.pair([person]) }.to raise_error(StandardError, 'There should be at least two people in the database')
    end
  end

  context 'when there are two or more people in the database' do
    it 'shuffles them and pairs them up' do
      pairs = RandomPairer.pair(people)
      expect(pairs[0].length).to eq(2)
      expect(pairs[1].length).to eq(1)
    end
  end
end
