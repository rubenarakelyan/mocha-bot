class RandomPairer
  def self.pair(people)
    # We don't explicitly handle having an odd number of people here
    # A notification to this effect is produced further down the line
    # This method outputs an array of pairs
    # e.g. [['Person 1', 'Person 3'], ['Person 2', 'Person 4']]
    raise 'There are no people in the database' if people.empty?
    raise 'There should be at least two people in the database' if people.length < 2

    people.shuffle.each_slice(2).to_a
  end
end
