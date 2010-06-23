require 'date'
require 'time'
require 'rubygems'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'squealer'
require "spec_helper_dbms_#{ENV['EXPORT_DBMS']||'mysql'}"

Spec::Runner.configure do |config|
  config.before(:suite) do
    $db_name = "test_export_#{object_id}"
    create_export_db($db_name)
    create_import_db($db_name)
  end

  config.after(:suite) do
    Squealer::Database.instance.send(:dispose_all_connections)
    drop_export_test_db($db_name)

    drop_mongo
  end

  config.after(:each) do
    @export_dbc.dispose if @export_dbc
  end

  def create_import_db(name)
    Squealer::Database.instance.import_from('localhost', 27017, name)
    @mongo = Squealer::Database.instance.import.instance_variable_get('@dbc')
    drop_mongo
    seed_import
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
          { :_id => id, :name => 'Develop squealer', :due_date => as_time(Date.today + 1) },
          { :_id => id, :name => 'Organize speakerconf.com', :due_date => as_time(Date.today + 30) },
          { :_id => id, :name => 'Hashrocket party', :due_date => as_time(Date.today + 7) }
        ]
      },
      { :name => 'Bernerd Schaefer', :dob => as_time(Date.parse('31-Dec-1985')), :gender => 'M',
        :organization_id => hashrocket,
        :activities => [
          { :_id => id, :name => 'Retype all of the code Josh wrote in squealer', :due_date => as_time(Date.today + 2) },
          { :_id => id, :name => 'Listen to rare Thelonius Monk EP', :due_date => as_time(Date.today) },
          { :_id => id, :name => 'Practice karaoke', :due_date => as_time(Date.today + 7) }
        ]
      },
      { :name => 'Your momma', :dob => as_time(Date.parse('15-Jun-1955')), :gender => 'F',
        :organization_id => zorganization,
        :activities => [
          { :_id => id, :name => 'Cook me some pie', :due_date => as_time(Date.today) },
          { :_id => id, :name => 'Make me a sammich', :due_date => as_time(Date.today) }
        ]
      }
    ]

    users.each { |user| @mongo.collection('users').save user }
  end


  def truncate_export_tables
    non_query('TRUNCATE TABLE "user"')
    non_query('TRUNCATE TABLE "activity"')
    non_query('TRUNCATE TABLE "organization"')
  end

  def as_time(date)
    Time.parse(date.to_s)
  end

  def non_query(text)
    export_dbc.create_command(text).execute_non_query
  end

  def id
    require 'digest/sha1'
    (Digest::SHA1.hexdigest rand.to_s)[0,24]
  end
end
