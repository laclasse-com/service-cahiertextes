begin; require 'rubygems'; rescue LoadError; end

require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'
#require 'resque/tasks'

Dir.glob(File.expand_path('../tasks/*.rake', __FILE__)).each do |f|
  import(f)
end

RSpec::Core::RakeTask.new(:spec)
task :default => :spec