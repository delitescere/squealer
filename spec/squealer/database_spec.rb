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

  describe "import" do
    it "takes an import database" do
      Squealer::Database.instance.import_from('localhost', 27017, @db_name)
      Squealer::Database.instance.send(:instance_variable_get, '@import_dbc').should be_a_kind_of(Mongo::DB)
    end

    it "returns a squealer connection object" do
      Squealer::Database.instance.import_from('localhost', 27017, @db_name)
      Squealer::Database.instance.import.should be_a_kind_of(Squealer::Database::Connection)
    end
  end

  describe "source" do
    let(:mongodb) { Squealer::Database.instance }
    before { mongodb.import_from('localhost', 27017, @db_name) }

    it "returns a mongodb cursor" do
      mongodb.import.source("foo").should be_a_kind_of(Mongo::Cursor)
    end
    it "takes a total count from the cursor" do
      mongodb.import.source("foo")
      mongodb.import.collections["foo"].counts.should == {:total => 0}
    end

  end

  describe "export" do
    it "takes an export database" do
      Squealer::Database.instance.export_to('localhost', 'root', '', @db_name)
      Squealer::Database.instance.send(:instance_variable_get, '@export_dbc').should be_a_kind_of(Mysql)
    end
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
