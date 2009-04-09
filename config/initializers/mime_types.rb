# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register "application/atomsvc+xml", :atomsvc

ActionController::Base.param_parsers[Mime::Type.lookup("application/atom+xml")] = Proc.new do |body|
  begin
    { :atom => Atom::Entry.load_entry(body) } 
  rescue ArgumentError => e1
    begin
      { :atom => Atom::Feed.load_feed(body) }
    rescue ArgumentError => e2
      { :atom_error => ArgumentError.new("Could not parse request as either atom:feed or atom:entry. " +
                                         "Errors are '#{e1.message}' and '#{e2.message}'") }
    end
  end
end
