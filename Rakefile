require "bundler/gem_tasks"
require "rake/testtask"

namespace :test do
  Rake::TestTask.new(:postgres) do |t|
    t.description = "Run tests for Postgres"
    t.libs << "test"
    t.test_files = FileList["test/**/*_test.rb"].exclude("test/{mariadb,mysql,sqlite}_test.rb")
  end

  Rake::TestTask.new(:mysql) do |t|
    t.description = "Run tests for MySQL"
    t.libs << "test"
    t.test_files = FileList["test/**/mysql_test.rb"]
  end

  Rake::TestTask.new(:mariadb) do |t|
    t.description = "Run tests for MariaDB"
    t.libs << "test"
    t.test_files = FileList["test/**/mariadb_test.rb"]
  end

  Rake::TestTask.new(:sqlite) do |t|
    t.description = "Run tests for SQLite"
    t.libs << "test"
    t.test_files = FileList["test/**/sqlite_test.rb"]
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
