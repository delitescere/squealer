require 'mysql'
require 'mongo'
require 'singleton'

module Squealer
  class Database
    include Singleton

    def import_from(host, port, name)
      @import_dbc = Mongo::Connection.new(host, port, :slave_ok => true).db(name)
    end

    def export_to(host, username, password, name)
      @export_dbc = Mysql.connect(host, username, password, name)
    end

    def import
      @import_dbc
    end

    def export
      @export_dbc
    end

  end
end
