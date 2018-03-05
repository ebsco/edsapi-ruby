require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/*_test.rb']
  t.warning = false
end

Rake::TestTask.new(:test_caching) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/caching/*_test.rb']
  t.warning = false
end

Rake::TestTask.new(:test_session_using_env_vars) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/sessions/*_test.rb']
  t.warning = false
end

task :default => :test
