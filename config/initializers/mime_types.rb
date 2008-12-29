# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register "application/atomsvc+xml", :atomsvc

ActionController::Base.param_parsers[Mime::Type.lookup("application/atom+xml")] = Proc.new do |body|
  begin
    { :atom => Atom::Entry.load_entry(body) } 
  rescue ArgumentError
    begin
      { :atom => Atom::Feed.load_feed(body) }
    # on the ci server, an ArgumentError is thrown here
    rescue ArgumentError, Atom::ParseError => ape
      { :atom_error => ape }
    end
  rescue Atom::ParseError => ape
    { :atom_error => ape }
  end
end
