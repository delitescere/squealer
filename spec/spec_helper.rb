require 'date'
require 'time'
require 'rubygems'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'squealer'

def as_time(date)
  Time.parse(date.to_s)
end

def id
  require 'digest/sha1'
  (Digest::SHA1.hexdigest rand.to_s)[0,24]
end
