require 'date'
require 'time'
require 'rubygems'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'squealer'

Spec::Runner.configure do |config|
  config.before(:suite) do
    $db_name = "test_export_#{object_id}"
    create_test_db($db_name)
  end

  config.after(:suite) do
    drop_test_db($db_name)
  end

  def create_test_db(name)
    dbc = DataObjects::Connection.new("mysql://root@localhost/mysql")
    dbc.create_command("DROP DATABASE IF EXISTS #{name}").execute_non_query
    dbc.create_command("CREATE DATABASE #{name}").execute_non_query
    dbc.create_command("SET sql_mode='ANSI_QUOTES'").execute_non_query

    create_export_tables

    Squealer::Database.instance.import_from('localhost', 27017, $db_name)
    @mongo = Squealer::Database.instance.import.send(:instance_variable_get, '@dbc')
    drop_mongo
    seed_import
  end

  def drop_test_db(name)
    @my.close if @my
    dbc = DataObjects::Connection.new("mysql://root@localhost/mysql")
    dbc.create_command("DROP DATABASE IF EXISTS #{name}").execute_non_query
    dbc.close

    drop_mongo
  end

  def drop_mongo
    @mongo.eval('db.dropDatabase()') if @mongo
  end

  def seed_import
    hashrocket = @mongo.collection('organizations').save({ :name => 'Hashrocket' })
    zorganization = @mongo.collection('organizations').save({ :name => 'Zorganization', :disabled_date => as_time(Date.today) })

    users = [
      { :name => 'Josh Graham', :dob => as_time(Date.parse('01-Jan-1971')), :gender => 'M',
        :organization_id => hashrocket,
        :activities => [
          { :name => 'Develop squealer', :due_date => as_time(Date.today + 1) },
          { :name => 'Organize speakerconf.com', :due_date => as_time(Date.today + 30) },
          { :name => 'Hashrocket party', :due_date => as_time(Date.today + 7) }
        ]
      },
      { :name => 'Bernerd Schaefer', :dob => as_time(Date.parse('31-Dec-1985')), :gender => 'M',
        :organization_id => hashrocket,
        :activities => [
          { :name => 'Retype all of the code Josh wrote in squealer', :due_date => as_time(Date.today + 2) },
          { :name => 'Listen to rare Thelonius Monk EP', :due_date => as_time(Date.today) },
          { :name => 'Practice karaoke', :due_date => as_time(Date.today + 7) }
        ]
      },
      { :name => 'Your momma', :dob => as_time(Date.parse('15-Jun-1955')), :gender => 'F',
        :organization_id => zorganization,
        :activities => [
          { :name => 'Cook me some pie', :due_date => as_time(Date.today) },
          { :name => 'Make me a sammich', :due_date => as_time(Date.today) }
        ]
      }
    ]

    users.each { |user| @mongo.collection('users').save user }
  end

  def create_export_tables
    command = <<-COMMAND.gsub(/\n\s*/, " ")
      CREATE TABLE "user" (
        "id" CHAR(24) NOT NULL ,
        "organization_id" CHAR(24) NOT NULL ,
        "name" VARCHAR(255) NULL ,
        "gender" CHAR(1) NULL ,
        "dob" DATETIME NULL ,
        "awesome" BOOLEAN NULL ,
        "fat" BOOLEAN NULL ,
        "symbolic" VARCHAR(255) NULL ,
        "interests" TEXT NULL ,
        PRIMARY KEY ("id") )
    COMMAND
    non_query(command)

    command = <<-COMMAND.gsub(/\n\s*/, " ")
      CREATE TABLE "activity" (
        "id" CHAR(24) NOT NULL ,
        "user_id" CHAR(24) NULL ,
        "name" VARCHAR(255) NULL ,
        "due_date" DATETIME NULL ,
        PRIMARY KEY ("id") )
    COMMAND
    non_query(command)

    command = <<-COMMAND.gsub(/\n\s*/, " ")
      CREATE TABLE "organization" (
        "id" CHAR(24) NOT NULL ,
        "disabled_date" DATETIME NULL ,
        PRIMARY KEY ("id") )
    COMMAND
    non_query(command)
  end

  def truncate_export_tables
    non_query('DELETE FROM "user"')
    non_query('TRUNCATE TABLE "activity"')
    non_query('TRUNCATE TABLE "organization"')
  end

  def as_time(date)
    Time.parse(date.to_s)
  end

  def non_query(text)
    my.create_command(text).execute_non_query
  end

  def my
    @my ||= DataObjects::Connection.new("mysql://root@localhost/#{$db_name}")
  end
end
