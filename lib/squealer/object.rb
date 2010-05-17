class Object

  def target(table_name, row_id=nil, &block)
    Squealer::Target.new(Squealer::Database.instance.export, table_name, row_id, &block)
  end

  def assign(column_name, &block)
    Squealer::Target.current.assign(column_name, &block)
  end

  def import(*args)
    if args.length > 0
      Squealer::Database.instance.import_from(*args)
    else
      Squealer::Database.instance.import
    end
  end

  def export(*args)
    if args.length > 0
      Squealer::Database.instance.export_to(*args)
    else
      Squealer::Database.instance.export
    end
  end

end

class NilClass
  def each
    []
  end
end
