require 'do_mysql'

$do_adapter = 'mysql'
$do_host = 'localhost'
$do_user = 'root'
$do_pass = ''

def create_export_db(name)
  dbc = do_conn_default
  dbc.create_command("DROP DATABASE IF EXISTS #{name}").execute_non_query
  dbc.create_command("CREATE DATABASE #{name}").execute_non_query
  dbc.create_command("SET sql_mode='ANSI_QUOTES'").execute_non_query
  dbc.release
  create_export_tables
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
