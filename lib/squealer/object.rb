class Object

  def target(table_name, &block)
    Squealer::Target.new(Squealer::Database.instance.export, table_name, &block)
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
  include Enumerable
  def each
    []
  end
end
