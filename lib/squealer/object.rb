class Object

  def target(table_name, row_id, &block)
    Target.new(Database.instance.export, table_name, row_id, &block)
  end

  def assign(column_name, &block)
    Target.current.assign(column_name, &block)
  end

  def import(database)
    Database.instance.import = database
  end

  def export(database)
    Database.instance.export = database
  end

end
