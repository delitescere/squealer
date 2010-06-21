class Hash
  def method_missing(name, *args, &block)
    super if args.size > 0 || block_given?
    #TODO: Warn if key doesn't exist - it's probably a typo in their squealer script
    self[name.to_s]
  end
end
