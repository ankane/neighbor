require "bundler/gem_tasks"
require "rake/testtask"

namespace :test do
  Rake::TestTask.new(:postgresql) do |t|
    t.description = "Run tests for Postgres"
    t.test_files = FileList["test/**/*_test.rb"].exclude("test/{sqlite,sqlitevec,vec1,mariadb,mysql}_*test.rb")
  end

  Rake::TestTask.new(:sqlite) do |t|
    t.description = "Run tests for SQLite"
    t.test_files = FileList["test/**/sqlite_*test.rb"]
  end

  Rake::TestTask.new(:sqlitevec) do |t|
    t.description = "Run tests for sqlite-vec"
    t.test_files = FileList["test/**/sqlitevec_*test.rb"]
  end

  Rake::TestTask.new(:vec1) do |t|
    t.description = "Run tests for Vec1"
    t.test_files = FileList["test/**/vec1_*test.rb"]
  end

  Rake::TestTask.new(:mariadb) do |t|
    t.description = "Run tests for MariaDB"
    t.test_files = FileList["test/**/mariadb_*test.rb"]
  end

  Rake::TestTask.new(:mysql) do |t|
    t.description = "Run tests for MySQL"
    t.test_files = FileList["test/**/mysql_*test.rb"]
  end
end

task :test do
  [:postgresql, :sqlite, :sqlitevec, :mariadb, :mysql].each do |adapter|
    next if adapter == :sqlitevec && RUBY_ENGINE == "truffleruby"
    puts "Using #{adapter}"
    Rake::Task["test:#{adapter}"].invoke
  end
end

task default: :test

task :benchmark do
  require "active_record"
  require "benchmark/ips"
  require "neighbor"

  ActiveRecord::Base.establish_connection adapter: "sqlite3", database: "/tmp/bench.sqlite3"

  class Item < ActiveRecord::Base
    has_neighbors :embedding, dimensions: 128
  end

  setup = false
  if setup
    ActiveRecord::Schema.define do
      create_table :items, force: true do |t|
        t.binary :embedding
      end
    end

    Item.insert_all!(100000.times.map { {embedding: 128.times.map { rand }} })

    ActiveRecord::Base.connection_handler.clear_all_connections!
  end

  # Neighbor::SQLite.initialize!(extension: "/tmp/vec1.so")

  embedding = 128.times.map { rand }
  Benchmark.ips do |x|
    x.report { Item.nearest_neighbors(:embedding, embedding, distance: "euclidean").first }
  end
end
