require "bundler/gem_tasks"
require "rake/testtask"

namespace :test do
  task("env:mariadb") { ENV["TEST_MARIADB"] = "1" }
  task("env:mysql") { ENV["TEST_MYSQL"] = "1" }
  task("env:postgresql") { ENV["TEST_POSTGRESQL"] = "1" }

  Rake::TestTask.new(mysql: "env:mysql") do |t|
    t.description = "Run tests for MySQL"
    t.libs << "test"
    t.test_files = FileList["test/**/mysql_test.rb"]
  end

  Rake::TestTask.new(mariadb: "env:mariadb") do |t|
    t.description = "Run tests for MariaDB"
    t.libs << "test"
    t.test_files = FileList["test/**/mariadb_test.rb"]
  end
end

Rake::TestTask.new(test: "test:env:postgresql") do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/{mariadb,mysql}_test.rb")
end

task default: :test
