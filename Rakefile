# -*- coding: utf-8 -*-
require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'

Dir.glob(File.expand_path('../tasks/*.rake', __FILE__)).each do |f|
  import(f)
end

RSpec::Core::RakeTask.new(:spec)
task default: :spec
