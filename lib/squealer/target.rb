require 'delegate'
require 'singleton'

#TODO: Use logger and log throughout

module Squealer
  class Target

    def self.current
      Queue.instance.current
    end

    def initialize(database_connection, table_name, &block)
      raise BlockRequired, "Block must be given to target (otherwise, there's no work to do)" unless block_given?
      raise ArgumentError, "Table name must be supplied" if table_name.to_s.strip.empty?

      @dbc = database_connection
      @table_name = table_name.to_s
      @binding = block.binding

      verify_table_name_in_scope
      @row_id = infer_row_id
      @column_names = []
      @column_values = []
      @sql = ''

      target(&block)
    end

    def sql
      @sql
    end

    def assign(column_name, &block)
      @column_names << column_name
      if block_given?
        @column_values << yield
      else
        @column_values << infer_value(column_name, @binding)
      end
    end


    private

    def infer_row_id
      (
        (eval "#{@table_name}[:_id]", @binding, __FILE__, __LINE__) ||
        (eval "#{@table_name}['_id']", @binding, __FILE__, __LINE__)
      ).to_s
    end
3
    def verify_table_name_in_scope
      table = eval "#{@table_name}", @binding, __FILE__, __LINE__
      raise ArgumentError, "The variable '#{@table_name}' is not a hashmap" unless table.is_a? Hash
      raise ArgumentError, "The hashmap '#{@table_name}' must have an '_id' key" unless table.has_key?('_id') || table.has_key?(:_id)
    rescue NameError
      raise NameError, "A variable named '#{@table_name}' must be in scope, and reference a hashmap with at least an '_id' key."
    end


    def infer_value(column_name, binding)
      value = eval "#{@table_name}.#{column_name}", binding, __FILE__, __LINE__
      unless value
        name = column_name.to_s
        if name =~ /_id$/
          related = name[0..-4]  #strip "_id"
          value = eval "#{related}._id", binding, __FILE__, __LINE__
        end
      end
      value
    end

    def target
      Queue.instance.push(self)

      yield self

      insert_statement = %{INSERT INTO "#{@table_name}"}
      insert_statement << %{ (#{pk_name}#{column_names}) VALUES ('#{@row_id}'#{column_value_markers})}
      if Database.instance.upsertable?
        insert_statement << %{ ON DUPLICATE KEY UPDATE #{column_markers}}
        @sql = insert_statement
      else
        update_statement = %{UPDATE "#{@table_name}" SET #{column_markers} WHERE #{pk_name}='#{@row_id}'}
        process_sql(update_statement)
        @sql = update_statement + "; " + insert_statement
      end

      process_sql(insert_statement)

      Queue.instance.pop
    end

    def self.targets
      @@targets
    end

    def targets
      @@targets
    end

    def process_sql(sql)
      values = Database.instance.upsertable? ? typecast_values * 2 : typecast_values
      execute_sql(sql, values)
    end

    def execute_sql(sql, values)
      @dbc.create_command(sql).execute_non_query(*values)
    rescue DataObjects::IntegrityError
      raise "Failed to execute statement: #{sql} with #{values.inspect}.\nOriginal Exception was: #{$!.to_s}" if Database.instance.upsertable?
    rescue
      raise "Failed to execute statement: #{sql} with #{values.inspect}.\nOriginal Exception was: #{$!.to_s}"
    end

    def pk_name
      'id'
    end

    def column_names
      return if @column_names.size == 0
      ",#{@column_names.map { |name| quote_identifier(name) }.join(',')}"
    end

    def column_values
      @column_values
    end

    def column_value_markers
      return if @column_names.size == 0
      result = ""
      @column_names.size.times { result << ',?'}
      result
    end

    def column_markers
      return if @column_names.size == 0
      result = ""
      @column_names.each {|k| result << "#{quote_identifier(k)}=?," }
      result.chop
    end

    def typecast_values
      column_values.map do |value|
        case value
        when Array
          value.join(",")
        when BSON::ObjectID
          value.to_s
        else
          value
        end
      end
    end

    def quote_identifier(name)
      %{"#{name}"}
    end

    class Queue < DelegateClass(Array)
      include Singleton

      def current
        last
      end

      protected

      def initialize
        super([])
      end
    end

    class BlockRequired < ArgumentError; end

  end
end
