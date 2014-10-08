# -*- coding: utf-8 -*-
begin; require 'rubygems'; rescue LoadError; end

require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'
#require 'resque/tasks'
require 'jasmine'

Dir.glob(File.expand_path('../tasks/*.rake', __FILE__)).each do |f|
  import(f)
end
load 'jasmine/tasks/jasmine.rake'

RSpec::Core::RakeTask.new(:spec)
task default: :spec
