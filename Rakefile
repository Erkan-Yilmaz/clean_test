require 'bundler'
require 'rake/clean'
require 'rake/testtask'
gem 'rdoc' # I need to use the installed RDoc gem, not what comes with the system
require 'rdoc/task'

include Rake::DSL

Bundler::GemHelper.install_tasks

desc 'run tests'
Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList['test/bootstrap.rb','test/test_*.rb']
end

desc 'build rdoc'
RDoc::Task.new do |rd|
  rd.main = "README.rdoc"
  rd.generator = 'hanna'
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Methadone - Power Up your Command Line Apps'
  rd.markup = "tomdoc"
end