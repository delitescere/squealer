require 'mysql'
require 'mongo'
require 'spec_helper'

describe Squealer::Database do

  before(:all) do
    @db_name = "test_export_#{object_id}"
    create_test_db(@db_name)
  end

  after(:all) do
    drop_test_db(@db_name)
  end

  it "is a singleton" do
    Squealer::Database.respond_to?(:instance).should be_true
  end

  it "takes an import database" do
    Squealer::Database.instance.import = @db_name
    Squealer::Database.instance.import.should be_a_kind_of(Mongo::DB)
  end

  it "takes an export database" do
    Squealer::Database.instance.export = @db_name
    Squealer::Database.instance.export.should be_a_kind_of(Mysql)
  end

  private

  def create_test_db(name)
    @my = Mysql.connect('localhost', 'root')
    @my.query("create database #{name}")
  end

  def drop_test_db(name)
    @my.query("drop database #{name}")
    @my.close
  end
end
