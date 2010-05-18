require 'mysql'
require 'mongo'
require 'singleton'

module Squealer
  class Database
    include Singleton

    def import_from(host, port, name)
      @import_dbc = Mongo::Connection.new(host, port, :slave_ok => true).db(name)
      @import_connection = Connection.new(@import_dbc)
    end

    def export_to(host, username, password, name)
      @export_dbc = Mysql.connect(host, username, password, name)
    end

    def import
      @import_connection
    end

    def export
      @export_dbc
    end

    class Connection
      attr_reader :collections

      def initialize(dbc)
        @dbc = dbc
        @collections = {}
      end

      def source(collection, conditions = {}, &block)
        source = Source.new(@dbc, collection)
        @collections[collection] = source
        source.source(conditions, &block)
      end

      def eval(string)
        @dbc.eval(string)
      end
    end

    class Source
      attr_reader :counts, :cursor

      def initialize(dbc, collection)
        @counts = {:exported => 0, :imported => 0}
        @collection = dbc.collection(collection)
      end

      def source(conditions)
        @cursor = block_given? ? yield(@collection) : @collection.find(conditions)
        @counts[:total] = cursor.count
        self
      end

      def each
        @cursor.each do |row|
          @counts[:imported] += 1
          yield row
          @counts[:exported] += 1
        end
      end
    end
  end
end
