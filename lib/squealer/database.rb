require 'singleton'

class Database
  include Singleton

  attr_accessor :import, :export
end
