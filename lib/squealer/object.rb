class Object
  def target(table_name, row_id, &block)
    Target.new(nil, table_name, row_id, &block)
  end

end
