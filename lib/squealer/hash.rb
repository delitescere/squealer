class Hash
  def method_missing(name, *args, &block)
    super if args.size > 0 || block_given?
    self[name.to_s]
  end
end
