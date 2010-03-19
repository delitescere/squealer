require 'mysql'
require 'mongo'
require 'singleton'

module Squealer
  class Database
    include Singleton

    def import=(name)
      config = lookup_in_database_mongo_yml(name)
      @import_dbc = Mongo::Connection.new(config[:host], config[:port], :slave_ok => true).db(name)
    end

    def export=(name)
      config = lookup_in_database_yml(name)
      @export_dbc = Mysql.connect(config[:host], config[:username], config[:password], name)
    end

    def import
      @import_dbc
    end

    def export
      @export_dbc
    end

    private

    def lookup_in_database_yml(name)
      config = {}

      config[:host] = 'localhost'
      config[:username] = 'root'
      config[:password] = ''

      config
    end

    def lookup_in_database_mongo_yml(name)
      config = {}

      config[:host] = 'localhost'
      config[:port] = 27017

      config
    end

  end
end
