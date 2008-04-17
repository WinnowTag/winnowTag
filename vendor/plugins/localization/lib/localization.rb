module Localization
  mattr_accessor :lang
  
  @@l10s = { :default => {} }
  @@lang = :default
  
  def self._(key, *args)
    translated = @@l10s[@@lang][key]
    raise "LocalizationError: could not find text for #{key.inspect}" unless translated

    if translated.is_a?(Hash)
      translated = if args[0] == 1
        translated[:singular]
      else
        translated[:plural]
      end
    end

    # if translated.is_a?(Proc)
    #   translated = translated.call(*args).to_s
    # end

    sprintf translated, *args
  end
  
  def self.define(lang = :default)
    @@l10s[lang] ||= {}
    yield @@l10s[lang]
  end
  
  def self.load
    Dir.glob("#{RAILS_ROOT}/lang/*.rb"){ |t| require t }
  end
  
  def self.generate_l10n_file
    "Localization.define('en_US') do |l|\n" <<
    Dir.glob("#{RAILS_ROOT}/app/**/*.*").collect do |f| 
      ["# #{f}"] << File.read(f).scan(/[^\w]_\([:](.*?)\)/)
    end.uniq.flatten.collect do |g|
      g.starts_with?('#') ? "\n  #{g}" : "  l.store '#{g}', '#{g}'"
    end.uniq.join("\n") << "\nend"
  end
end

class Object
  def _(*args); Localization._(*args); end
end