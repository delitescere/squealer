def create_export_db(name)
  require 'do_mysql'
  $db_adapter = 'mysql'
  dbc = DataObjects::Connection.new("mysql://root@localhost/mysql")
  dbc.create_command("DROP DATABASE IF EXISTS #{name}").execute_non_query
  dbc.create_command("CREATE DATABASE #{name}").execute_non_query
  dbc.create_command("SET sql_mode='ANSI_QUOTES'").execute_non_query
  create_export_tables
  dbc.dispose
end

def drop_export_test_db(name)
  @export_dbc.dispose if @export_dbc
  dbc = DataObjects::Connection.new("mysql://root@localhost/mysql")
  dbc.create_command("DROP DATABASE IF EXISTS #{name}").execute_non_query
  dbc.dispose
end

def create_export_tables
  command = <<-COMMAND.gsub(/\n\s*/, " ")
      CREATE TABLE "user" (
        "id" CHAR(24) NOT NULL ,
        "organization_id" CHAR(24) NOT NULL ,
        "name" VARCHAR(255) NULL ,
        "gender" CHAR(1) NULL ,
        "dob" DATETIME NULL ,
        "foreign" BOOLEAN NULL ,
        "dull" BOOLEAN NULL ,
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

def export_dbc
  $db_user ||= 'root'
  @export_dbc ||= DataObjects::Connection.new("mysql://root@localhost/#{$db_name}")
end
