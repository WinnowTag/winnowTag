# Copied from trunk of active support so we can use active resource
#
# TODO Remove when updating to Rails 2.0
#
class Hash
  def to_query(namespace = nil)
    collect do |key, value|
      value.to_query(namespace ? "#{namespace}[#{key}]" : key)
    end.sort * '&'
  end
end

# Extensions needed for Hash#to_query
class Object
  def to_param #:nodoc:
    to_s
  end

  def to_query(key) #:nodoc:
    "#{CGI.escape(key.to_s)}=#{CGI.escape(to_param.to_s)}"
  end
end

class Array
  def to_query(key) #:nodoc:
    collect { |value| value.to_query("#{key}[]") } * '&'
  end
end