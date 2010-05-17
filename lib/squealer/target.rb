require 'delegate'
require 'singleton'

#TODO: Use logger and log throughout
#TODO: Counters and timers

module Squealer
  class Target

    def self.current
      Queue.instance.current
    end

    def initialize(database_connection, table_name, row_id=nil, &block)
      raise BlockRequired, "Block must be given to target (otherwise, there's no work to do)" unless block_given?
      raise ArgumentError, "Table name must be supplied" if table_name.to_s.strip.empty?

      @table_name = table_name.to_s
      @row_id = obtain_row_id(row_id, &block)
      @column_names = []
      @column_values = []
      @sql = ''

      target(&block)
    end

    def sql
      @sql
    end

    def assign(column_name, &block)
      raise BlockRequired, "At least specify an empty block, like this:\n  assign(:#{column_name}) {}" unless block_given?
      @column_names << column_name
      @column_values << (yield || infer_value(column_name, &block))
    end


    private

    def obtain_row_id(row_id, &block)
      #TODO: Remove in version 1.3 - just call infer_row_id in initialize
      if row_id != nil
        puts "\033[33mWARNING - squealer:\033[0m the 'target' row_id parameter is deprecated and will be invalid in version 1.3 and above. Remove it, and ensure the table_name matches a variable containing a hashmap with an _id key"
        row_id
      else
        infer_row_id(&block)
      end
    end

    def infer_row_id(&block)
      block.binding.eval "#{@table_name}._id"
    end

    def infer_value(column_name, &block)
      value = block.binding.eval "#{@table_name}.#{column_name}"
      unless value
        name = column_name.to_s
        if name.end_with?("_id")
          related = name[0..-4]  #strip "_id"
          value = block.binding.eval "#{related}._id"
        end
      end
      value
    end

    def target(&block)
      Queue.instance.push(self)

      yield self

      @sql = "INSERT #{@table_name}"
      @sql << " (#{pk_name}#{column_names}) VALUES (?#{column_value_markers})"
      @sql << " ON DUPLICATE KEY UPDATE #{column_markers}"

      execute_sql(@sql)

      Queue.instance.pop
    end

    def self.targets
      @@targets
    end

    def targets
      @@targets
    end

    def execute_sql(sql)
      statement = Database.instance.export.prepare(sql)
      values = [*column_values] + [*column_values]  #array expando
      statement.send(:execute, @row_id, *values) #expand values into distinct arguments
    end

    def pk_name
      'id'
    end

    def column_names
      return if @column_names.size == 0
      ",#{@column_names.join(',')}"
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
      @column_names.each {|k| result << "#{k}=?," }
      result.chop
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
