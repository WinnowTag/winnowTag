# Use SQL Session Store
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:database_manager => SqlSessionStore)
SqlSessionStore.session_class = MysqlSession

# ActionController::Base.fragment_cache_store = :file_store, File.join(RAILS_ROOT, 'tmp', 'cache')

ExceptionNotifier.exception_recipients = %w(wizzadmin@peerworks.org)
ExceptionNotifier.email_prefix = "[WINNOW] "
ExceptionNotifier.sender_address = %("Winnow Admin" <wizzadmin@peerworks.org>)

require 'hash_ext'
require 'module_ext'

# winnow_collect_log_file 
# based on the comment above regarding RAILS_ROOT being set incorrect I'll use 
# relative paths
logger_suffix = RAILS_ENV == 'test' ? 'test' : ""
WINNOW_COLLECT_LOG = File.join(RAILS_ROOT, 'log', "winnow_collect.log#{logger_suffix}")

# And now some Monkey Patching

# Patch CGI::unescapeHTML to ignore non-printable characters and not escape ampersands
# that are already part of an escape.  This is to better handle special characters in
# FeedTools
#  
class CGI
  def CGI.escapeHTML(string)    
    string.gsub(/&(?!((\w|\d)+|\#\d+|\#x[0-9A-F]+);)/, '&amp;').gsub(/\"/n, '&quot;').gsub(/>/n, '&gt;').gsub(/</n, '&lt;')    
  end
  
  def CGI.unescapeHTML(string)
    string.gsub(/&(.*?);/n) do
      match = $1.dup
      case match
      when /\Aamp\z/ni           then '&'
      when /\Aquot\z/ni          then '"'
      when /\Agt\z/ni            then '>'
      when /\Alt\z/ni            then '<'
      when /\A#0*(\d+)\z/n       then
        if Integer($1) < 128  # Change from 256 to 128
          Integer($1).chr
        else
          if Integer($1) < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
            [Integer($1)].pack("U")
          else
            "&##{$1};"
          end
        end
      when /\A#x([0-9a-f]+)\z/ni then
        if $1.hex < 128 # Change from 256 to 128
          $1.hex.chr
        else
          if $1.hex < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
            [$1.hex].pack("U")
          else
            "&#x#{$1};"
          end
        end
      else
        "&#{match};"
      end
    end
  end
end

module UrlWithViewId
  def self.included(base)
    base.alias_method_chain :url_for, :view_id
  end
  
  def url_for_with_view_id(options = {})
    if @view
      if options.kind_of? Hash
        options = { :view_id => @view.id }.update(options.symbolize_keys)
      elsif options.kind_of? String
        unless options.include?("view_id=")
          if options.include?("?")
            options << "&view_id=#{@view.id}"
          else
            options << "?view_id=#{@view.id}"
          end
        end
      end
    end
    
    url_for_without_view_id(options)
  end
end
ActionView::Base.send :include, UrlWithViewId
ActionController::Base.send :include, UrlWithViewId