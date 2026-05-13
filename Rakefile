require "bundler/gem_tasks"
require "rake/testtask"

namespace :test do
  Rake::TestTask.new(:postgresql) do |t|
    t.description = "Run tests for Postgres"
    t.test_files = FileList["test/**/*_test.rb"].exclude("test/{sqlitevec,vec1,mariadb,mysql}*_test.rb")
  end

  Rake::TestTask.new(:sqlitevec) do |t|
    t.description = "Run tests for sqlite-vec"
    t.test_files = FileList["test/**/sqlitevec*_test.rb"]
  end

  Rake::TestTask.new(:vec1) do |t|
    t.description = "Run tests for Vec1"
    t.test_files = FileList["test/**/vec1*_test.rb"]
  end

  Rake::TestTask.new(:mariadb) do |t|
    t.description = "Run tests for MariaDB"
    t.test_files = FileList["test/**/mariadb*_test.rb"]
  end

  Rake::TestTask.new(:mysql) do |t|
    t.description = "Run tests for MySQL"
    t.test_files = FileList["test/**/mysql*_test.rb"]
  end
end

task :test do
  [:postgresql, :sqlitevec, :mariadb, :mysql].each do |adapter|
    next if adapter == :sqlitevec && RUBY_ENGINE == "truffleruby"
    puts "Using #{adapter}"
    Rake::Task["test:#{adapter}"].invoke
  end
end

task default: :test
