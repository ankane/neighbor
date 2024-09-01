require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/mysql_test.rb")
end

task default: :test

namespace :test do
  task("env:mysql") { ENV["TEST_MYSQL"] = "1" }

  Rake::TestTask.new(mysql: "env:mysql") do |t|
    t.description = "Run tests for MySQL"
    t.libs << "test"
    t.test_files = FileList["test/**/mysql_test.rb"]
  end
end
