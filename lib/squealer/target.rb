class Target
  def initialize(database_connection, table_name, row_id, &block)
    throw "Block must be given to target (otherwise, there's no work to do)" unless block_given?

    @table_name = table_name.to_s
    @row_id = row_id
    @column_names = []
    @column_values = []
    @sql = ''

    target(&block)
  end

  def sql
    @sql
  end

  def target(&block)
    yield(self)

    @sql = "INSERT #{@table_name}"
    @sql << " (#{pk_name}#{column_names}) VALUES (#{@row_id}#{column_values})"
    @sql << " ON DUPLICATE KEY UPDATE #{columns}"

    # execute @sql
  end

   def assign(column_name, &block)
     @column_names << column_name
     @column_values << block.call
   end

  private

  def pk_name
    'id'
  end

  def column_names
    return if @column_names.size == 0
    ",#{@column_names.join(',')}"
  end

  def column_values
    return if @column_names.size == 0
    result = ","
    @column_values.each {|v| result << "'#{v}'," }
    result.chop
  end

  def columns
    return if @column_names.size == 0
    result = ""
    @column_names.each_with_index {|k,i| result << "#{k}='#{@column_values[i]}'," }
    result.chop
  end
end
