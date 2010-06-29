require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + "/./spec_helper_dbms_#{ENV['EXPORT_DBMS']||'mysql'}")

Spec::Runner.configure do |config|
  config.before(:suite) do
    $db_name = "squealer_test_export_#{object_id}"
    create_export_db($db_name)
    create_import_db($db_name)
  end

  config.after(:suite) do
    DataObjects::Pooling.pools.each {|pool| pool.flush!}
    drop_export_test_db($db_name)

    drop_mongo
  end

  config.before(:each) do
    if self.class.example_implementations.first.first.location =~ %r{/spec/integration/}
      Squealer::Database.instance.export_to($do_adapter, $do_host, $do_user, $do_pass, $db_name)
      truncate_export_tables(Squealer::Database.instance.export)
    end
  end
  config.after(:each) do
    if self.class.example_implementations.first.first.location =~ %r{/spec/integration/}
      Squealer::Database.instance.export.release
    end
  end
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


def truncate_export_tables(dbc)
  %w{user activity organization}.each do |t|
    text = %{TRUNCATE TABLE "#{t}"}
    dbc.create_command(text).execute_non_query
  end
end

def non_query(text)
  dbc = do_conn
  dbc.create_command(text).execute_non_query
  dbc.release
end

def drop_export_test_db(name)
  dbc = do_conn_default
  dbc.create_command("DROP DATABASE IF EXISTS #{name}").execute_non_query
  dbc.release
end

def do_conn
  DataObjects::Connection.new("#{$do_adapter}://#{at_host}/#{$db_name}")
end

def do_conn_default
  DataObjects::Connection.new("#{$do_adapter}://#{at_host}/#{$do_adapter}")
end

def at_host
  creds = ""
  creds << $do_user if $do_user
  creds << ":#{$do_pass}" if $do_pass

  at_host = ""
  at_host << "#{creds}@" unless creds.empty?
  at_host << $do_host
end
