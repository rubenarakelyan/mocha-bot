# `spec` task
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

# `lint` task
desc 'Run rubocop linting'
task :lint do
  sh 'bundle exec rubocop'
end

task default: %i[spec lint]
