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
    let(:mongodbc) { Squealer::Database.instance }

    before { mongodbc.import_from('localhost', 27017, @db_name) }

    it "takes an import database" do
      mongodbc.send(:instance_variable_get, '@import_dbc').should be_a_kind_of(Mongo::DB)
    end

    it "returns a squealer connection object" do
      mongodbc.import.should be_a_kind_of(Squealer::Database::Connection)
    end

    it "delegates eval to Mongo" do
      mongodbc.send(:instance_variable_get, '@import_dbc').eval('db.getName()').should == @db_name
      mongodbc.import.eval('db.getName()').should == @db_name
    end
  end

  describe "source" do
    let(:mongodbc) { Squealer::Database.instance }

    before { mongodbc.import_from('localhost', 27017, @db_name) }

    it "returns a mongodbc cursor" do
      mongodbc.import.source('foo').should be_a_kind_of(Mongo::Cursor)
    end

    it "counts a total of zero for an empty collection" do
      mongodbc.import.source('foo')
      mongodbc.import.collections['foo'].counts.should == {:total => 0}
    end

    it "counts a total of two from a collection with two documents" do
      # if this looks convoluted to try to use the import database connection
      # to perform updates, that's because it is. It's for _importing_.
      db = mongodbc.send(:instance_variable_get, '@import_dbc').connection.db(@db_name)
      db.collection('foo').save({'name' => 'Bar'});
      db.collection('foo').save({'name' => 'Baz'});
      mongodbc.import.source('foo') # activate the counter
      mongodbc.import.collections['foo'].counts.should == {:total => 2}
    end

  end

  describe "export" do
    let(:mongodbc) { Squealer::Database.instance }

    it "takes an export database" do
      mongodbc.export_to('localhost', 'root', '', @db_name)
      mongodbc.send(:instance_variable_get, '@export_dbc').should be_a_kind_of(Mysql)
    end
  end

  private

  def create_test_db(name)
    @my = Mysql.connect('localhost', 'root')
    @my.query("DROP DATABASE IF EXISTS #{name}")
    @my.query("CREATE DATABASE #{name}")

    drop_mongo(name)
  end

  def drop_test_db(name)
    @my.query("DROP DATABASE IF EXISTS #{name}")
    @my.close

    drop_mongo(name)
  end

  def drop_mongo(name)
    mongo = Squealer::Database.instance.import.send(:instance_variable_get, '@dbc')
    mongo.eval('db.dropDatabase()') if mongo
  end
end
