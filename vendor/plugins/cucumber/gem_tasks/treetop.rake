class FeatureCompiler
  def initialize
    require 'yaml'
    require 'erb'
    
    @tt = PLATFORM =~ /mswin|mingw/ ? 'tt.bat' : 'tt'

    @template = ERB.new(IO.read(File.dirname(__FILE__) + '/../lib/cucumber/treetop_parser/feature.treetop.erb'))
    @langs = YAML.load_file(File.dirname(__FILE__) + '/../lib/cucumber/languages.yml')
  end
  
  def compile_all
    @langs.keys.each do |lang|
      compile(lang)
    end
  end
  
  def compile(lang)
    words = @langs['en'].merge(@langs[lang]) # Use English words if languages.yml is missing a word
    grammar_file = File.dirname(__FILE__) + "/../lib/cucumber/treetop_parser/feature_#{lang}.treetop"
    ruby_file    = File.dirname(__FILE__) + "/../lib/cucumber/treetop_parser/feature_#{lang}.rb"
    grammar      = @template.result(binding)
    File.open(grammar_file, "wb") do |io|
      io.write(grammar)
    end
    sh "#{@tt} #{grammar_file}"
    FileUtils.rm(grammar_file)
    
    # Change code so it isn't part of RDoc
    lines = IO.read(ruby_file).split("\n")
    lines.each do |line|
      if line =~ /\s*(def|class|module)/
        line << " #:nodoc:"
      end
    end
    File.open(ruby_file, 'wb'){|io| io.write(lines.join("\n"))}
  end
end

namespace :treetop do
  desc 'Compile the grammar for all languages in languages.yml'
  task :compile do
    FeatureCompiler.new.compile_all
  end

  task :compile_en do
    FeatureCompiler.new.compile('en')
  end
end