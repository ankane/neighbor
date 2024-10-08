require "bundler/gem_tasks"
require "rake/testtask"

namespace :test do
  Rake::TestTask.new(:postgresql) do |t|
    t.description = "Run tests for Postgres"
    t.libs << "test"
    t.test_files = FileList["test/**/*_test.rb"].exclude("test/{sqlite,mariadb,mysql}*_test.rb")
  end

  Rake::TestTask.new(:sqlite) do |t|
    t.description = "Run tests for SQLite"
    t.libs << "test"
    t.test_files = FileList["test/**/sqlite*_test.rb"]
  end

  Rake::TestTask.new(:mariadb) do |t|
    t.description = "Run tests for MariaDB"
    t.libs << "test"
    t.test_files = FileList["test/**/mariadb*_test.rb"]
  end

  Rake::TestTask.new(:mysql) do |t|
    t.description = "Run tests for MySQL"
    t.libs << "test"
    t.test_files = FileList["test/**/mysql*_test.rb"]
  end
end

task :test do
  [:postgresql, :sqlite, :mariadb, :mysql].each do |adapter|
    puts "Using #{adapter}"
    Rake::Task["test:#{adapter}"].invoke
  end
end

task default: :test
