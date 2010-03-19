class Object

  def target(table_name, row_id, &block)
    Squealer::Target.new(Squealer::Database.instance.export, table_name, row_id, &block)
  end

  def assign(column_name, &block)
    Squealer::Target.current.assign(column_name, &block)
  end

  def import(database)
    Squealer::Database.instance.import = database
  end

  def export(database)
    Squealer::Database.instance.export = database
  end

end

class NilClass
  def each
    []
  end
end
