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
    @my = Mysql.connect('localhost', 'root')
    @my.query("DROP DATABASE IF EXISTS #{name}")
    @my.query("CREATE DATABASE #{name}")
    @my.query("USE #{name}")
    @my.query("SET sql_mode='ANSI_QUOTES'")

    create_export_tables

    Squealer::Database.instance.import_from('localhost', 27017, $db_name)
    @mongo = Squealer::Database.instance.import.send(:instance_variable_get, '@dbc')
    drop_mongo
    seed_import
  end

  def drop_test_db(name)
    @my.query("DROP DATABASE IF EXISTS #{name}")
    @my.close

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
      CREATE TABLE "users" (
        "id" INT NOT NULL AUTO_INCREMENT ,
        "name" VARCHAR(255) NULL ,
        "gender" CHAR(1) NULL ,
        "dob" DATE NULL ,
        PRIMARY KEY ("id") )
    COMMAND
    @my.query(command)

    command = <<-COMMAND.gsub(/\n\s*/, " ")
      CREATE TABLE "activity" (
        "id" INT NOT NULL AUTO_INCREMENT ,
        "user_id" INT NULL ,
        "name" VARCHAR(255) NULL ,
        "due_date" DATE NULL ,
        PRIMARY KEY ("id") )
    COMMAND
    @my.query(command)

    command = <<-COMMAND.gsub(/\n\s*/, " ")
      CREATE TABLE "organizations" (
        "id" INT NOT NULL AUTO_INCREMENT ,
        "disabed_date" DATE NULL ,
        PRIMARY KEY ("id") )
    COMMAND
    @my.query(command)
  end

  def as_time(date)
    Time.parse(date.to_s)
  end
end
