require "bundler/gem_tasks"
require "rake/testtask"

namespace :test do
  Rake::TestTask.new(:postgresql) do |t|
    t.description = "Run tests for Postgres"
    t.libs << "test"
    t.test_files = FileList["test/**/*_test.rb"].exclude("test/sqlite*_test.rb")
  end

  Rake::TestTask.new(:sqlite) do |t|
    t.description = "Run tests for SQLite"
    t.libs << "test"
    t.test_files = FileList["test/**/sqlite*_test.rb"]
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
